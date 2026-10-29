import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_rasterizer.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

class FogChange {
  const FogChange(this.tiles, {this.all = false, this.flushed = false});

  /// Tiles whose content changed, on any level of the pyramid.
  final Set<FogTileId> tiles;

  /// True when the whole fog was replaced (cleared or rebuilt).
  final bool all;

  /// True when the change was written to storage, so coarser levels were
  /// refreshed too; false for a live update of the base level only.
  final bool flushed;
}

class FogStoreDiagnostics {
  const FogStoreDiagnostics({
    required this.cachedTiles,
    required this.dirtyTiles,
    required this.revision,
    required this.totalAreaM2,
    required this.appliedPoints,
    required this.lastApplyMicros,
    required this.lastFlushMillis,
    required this.lastFlushTiles,
  });

  final int cachedTiles;
  final int dirtyTiles;
  final int revision;
  final double totalAreaM2;
  final int appliedPoints;
  final int lastApplyMicros;
  final int lastFlushMillis;
  final int lastFlushTiles;
}

class _CacheEntry {
  _CacheEntry(this.mask, {this.areaM2 = 0});

  /// Null means "known to have no fog data".
  FogMask? mask;
  double areaM2;
  bool dirty = false;
}

class _Anchor {
  const _Anchor(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class _PathJob {
  _PathJob(this.xy, this.radii, {required this.continues});

  final Float64List xy;
  final Float64List radii;

  /// True when the first point was already drawn earlier.
  final bool continues;
}

class _DeferredPoint {
  _DeferredPoint(this.sessionId, this.latitude, this.longitude, this.logId);

  final String sessionId;
  final double latitude;
  final double longitude;
  final int? logId;
  final Completer<void> done = Completer<void>();
}

class _ChunkJob {
  _ChunkJob(this.zoom, this.edgeWidth, this.quantStep, this.paths);

  final int zoom;
  final double edgeWidth;
  final int quantStep;
  final List<_PathJob> paths;
}

List<(int, Uint8List?)> _encodeBatch(List<Uint8List> raw) {
  return [
    for (final data in raw)
      () {
        final encoded = FogTileCodec.encode(FogMask.fromBytes(data));
        return (encoded.flag, encoded.bytes);
      }(),
  ];
}

Map<int, Uint8List> _rasterizeChunk(_ChunkJob job) {
  final masks = <FogTileId, FogMask>{};
  final rasterizer = FogRasterizer(
    zoom: job.zoom,
    edgeWidth: job.edgeWidth,
    quantStep: job.quantStep,
  );
  FogMask provide(FogTileId id) => masks.putIfAbsent(id, FogMask.new);

  for (final path in job.paths) {
    final count = path.radii.length;
    if (!path.continues) {
      rasterizer.drawStadium(
        ax: path.xy[0],
        ay: path.xy[1],
        bx: path.xy[0],
        by: path.xy[1],
        radius: path.radii[0],
        maskFor: provide,
      );
    }
    for (var i = 1; i < count; i++) {
      rasterizer.drawStadium(
        ax: path.xy[2 * i - 2],
        ay: path.xy[2 * i - 1],
        bx: path.xy[2 * i],
        by: path.xy[2 * i + 1],
        radius: path.radii[i],
        maskFor: provide,
      );
    }
  }
  return {for (final e in masks.entries) e.key.key: e.value.data};
}

/// The fog of one user as tiles of 8-bit coverage.
///
/// New positions are rasterized into tiles immediately and written to
/// [storage] in batches. Every write also refreshes the coarser pyramid
/// levels used when the map is zoomed out. The tiles are a cache: the
/// authoritative history is the track log, which can rebuild them.
class FogStore {
  FogStore._(
    this.storage, {
    required this.baseZoom,
    required this.minZoom,
    required this.radiusMeters,
    required this.maxCachedTiles,
    required this.maxDirtyTiles,
    required this.flushDelay,
    required this.overviewFloor,
    required this.encodeInIsolate,
    required this.isolateEncodeThreshold,
    required this._rasterizer,
    required this._revision,
    required this._totalAreaM2,
    required this._lastAppliedLogId,
  });

  static Future<FogStore> open(
    FogTileStorage storage, {
    int baseZoom = FogConfig.baseZoom,
    int minZoom = FogConfig.minZoom,
    double radiusMeters = FogConfig.visionRadiusMeters,
    int maxCachedTiles = FogConfig.maxCachedTiles,
    int maxDirtyTiles = FogConfig.maxDirtyTiles,
    Duration flushDelay = FogConfig.flushDelay,
    int overviewFloor = FogPyramid.defaultOverviewFloor,
    double edgeWidth = FogConfig.edgeWidthPixels,
    bool encodeInIsolate = true,
    int isolateEncodeThreshold = FogConfig.isolateEncodeThreshold,
  }) async {
    var meta = await storage.loadMeta();
    final compatible =
        meta.isEmpty ||
        (meta['baseZoom'] == baseZoom &&
            meta['minZoom'] == minZoom &&
            meta['formatVersion'] == FogTileCodec.formatVersion);
    if (!compatible) {
      await storage.clear();
      meta = {};
    }
    return FogStore._(
      storage,
      baseZoom: baseZoom,
      minZoom: minZoom,
      radiusMeters: radiusMeters,
      maxCachedTiles: maxCachedTiles,
      maxDirtyTiles: maxDirtyTiles,
      flushDelay: flushDelay,
      overviewFloor: overviewFloor,
      encodeInIsolate: encodeInIsolate,
      isolateEncodeThreshold: isolateEncodeThreshold,
      rasterizer: FogRasterizer(
        zoom: baseZoom,
        edgeWidth: edgeWidth,
        quantStep: FogConfig.baseQuantStep,
      ),
      revision: meta['rev']?.toInt() ?? 0,
      totalAreaM2: meta['totalAreaM2'] ?? 0,
      lastAppliedLogId: meta['lastAppliedLogId']?.toInt() ?? 0,
    );
  }

  final FogTileStorage storage;
  final int baseZoom;
  final int minZoom;
  final double radiusMeters;
  final int maxCachedTiles;
  final int maxDirtyTiles;
  final Duration flushDelay;
  final int overviewFloor;

  /// Compress large writes in a background isolate to keep the UI smooth.
  final bool encodeInIsolate;
  final int isolateEncodeThreshold;
  final FogRasterizer _rasterizer;

  final LinkedHashMap<FogTileId, _CacheEntry> _cache = LinkedHashMap();
  final Set<FogTileId> _dirty = {};
  final Set<FogTileId> _pinned = {};
  final Map<String, _Anchor> _lastPoint = {};
  final List<_DeferredPoint> _deferred = [];
  final StreamController<FogChange> _changes =
      StreamController<FogChange>.broadcast();

  final SerialQueue _queue = SerialQueue();
  Timer? _flushTimer;
  bool _metaDirty = false;
  bool _disposed = false;

  /// Replays and rebuilds in progress; while any runs, new points wait.
  int _catchUps = 0;

  /// True after a replay failed: the log holds entries that are not drawn,
  /// so new points must not move [lastAppliedLogId] past them.
  bool _behindLog = false;

  int _revision;
  double _totalAreaM2;
  int _lastAppliedLogId;
  int _appliedPoints = 0;
  int _lastApplyMicros = 0;
  int _lastFlushMillis = 0;
  int _lastFlushTiles = 0;

  int get revision => _revision;

  /// Ground area revealed so far, in square meters, as of the last flush.
  double get totalAreaM2 => _totalAreaM2;

  /// Id of the newest track log entry already drawn into the tiles.
  int get lastAppliedLogId => _lastAppliedLogId;

  Stream<FogChange> get changes => _changes.stream;

  FogStoreDiagnostics get diagnostics => FogStoreDiagnostics(
    cachedTiles: _cache.length,
    dirtyTiles: _dirty.length,
    revision: _revision,
    totalAreaM2: _totalAreaM2,
    appliedPoints: _appliedPoints,
    lastApplyMicros: _lastApplyMicros,
    lastFlushMillis: _lastFlushMillis,
    lastFlushTiles: _lastFlushTiles,
  );

  /// Draws the segment from the previous point of [sessionId] to this one.
  /// A session's first point is drawn as a disc. [logId] is the track log id
  /// of the point, used to resume after a crash.
  ///
  /// During a replay or rebuild the point is drawn only after it finished,
  /// so log entries always reach the tiles in log order.
  Future<void> applyPoint({
    required String sessionId,
    required double latitude,
    required double longitude,
    int? logId,
  }) {
    if (_catchUps > 0) {
      final point = _DeferredPoint(sessionId, latitude, longitude, logId);
      _deferred.add(point);
      return point.done.future;
    }
    return _queue.run(() => _apply(sessionId, latitude, longitude, logId));
  }

  /// Draws the points that waited for a replay. Those the replay already
  /// read from the log are skipped.
  void _applyDeferred() {
    final points = List.of(_deferred);
    _deferred.clear();
    for (final point in points) {
      point.done.complete(
        _queue.run(() async {
          final logId = point.logId;
          if (logId != null && logId <= _lastAppliedLogId) return;
          await _apply(point.sessionId, point.latitude, point.longitude, logId);
        }),
      );
    }
  }

  Future<void> _apply(
    String sessionId,
    double latitude,
    double longitude,
    int? logId,
  ) async {
    final timer = Stopwatch()..start();
    final x = FogMercator.lngToX(longitude, baseZoom);
    final y = FogMercator.latToY(latitude, baseZoom);
    final radius = metersToPixels(
      meters: radiusMeters,
      latitude: latitude,
      zoom: baseZoom.toDouble(),
    );
    final previous = _lastPoint[sessionId];
    final ax = previous?.x ?? x;
    final ay = previous?.y ?? y;

    final reach = radius + _rasterizer.edgeWidth;
    final needed = _tilesCovering(
      math.min(ax, x) - reach,
      math.max(ax, x) + reach,
      math.min(ay, y) - reach,
      math.max(ay, y) + reach,
    );
    _pinned.addAll(needed);
    try {
      await _ensureLoaded(needed);
      final created = <FogTileId>{};
      final changed = <FogTileId>{};
      _rasterizer.drawStadium(
        ax: ax,
        ay: ay,
        bx: x,
        by: y,
        radius: radius,
        maskFor: (id) => _maskToDrawInto(id, created),
        onChanged: changed.add,
      );
      for (final id in changed) {
        _cache[id]!.dirty = true;
        _dirty.add(id);
      }
      // A tile that was only touched, without gaining a pixel, stays absent.
      for (final id in created.difference(changed)) {
        _cache[id]!.mask = null;
      }
      _rememberAnchor(sessionId, _Anchor(x, y, radius));
      _noteApplied(logId);
      if (changed.isNotEmpty && !_changes.isClosed) {
        _changes.add(FogChange(changed));
      }
    } finally {
      _pinned.removeAll(needed);
    }
    _appliedPoints++;
    _lastApplyMicros = timer.elapsedMicroseconds;
    await _flushIfNeeded();
  }

  void _noteApplied(int? logId) {
    if (_behindLog) return;
    if (logId != null && logId > _lastAppliedLogId) {
      _lastAppliedLogId = logId;
      _metaDirty = true;
    }
  }

  void _rememberAnchor(String sessionId, _Anchor anchor) {
    _lastPoint.remove(sessionId);
    _lastPoint[sessionId] = anchor;
    while (_lastPoint.length > 16) {
      _lastPoint.remove(_lastPoint.keys.first);
    }
  }

  List<FogTileId> _tilesCovering(
    double minX,
    double maxX,
    double minY,
    double maxY,
  ) {
    final tiles = 1 << baseZoom;
    const size = FogTileId.size;
    final x0 = (minX / size).floor().clamp(0, tiles - 1);
    final x1 = (maxX / size).floor().clamp(0, tiles - 1);
    final y0 = (minY / size).floor().clamp(0, tiles - 1);
    final y1 = (maxY / size).floor().clamp(0, tiles - 1);
    return [
      for (var ty = y0; ty <= y1; ty++)
        for (var tx = x0; tx <= x1; tx++) FogTileId(baseZoom, tx, ty),
    ];
  }

  /// The mask a shape is drawn into. It is not marked as modified here:
  /// only the rasterizer knows whether a pixel really changed.
  FogMask _maskToDrawInto(FogTileId id, Set<FogTileId> created) {
    final entry = _cache[id]!;
    _touch(id, entry);
    if (entry.mask == null) {
      entry.mask = FogMask();
      created.add(id);
    }
    return entry.mask!;
  }

  void _touch(FogTileId id, _CacheEntry entry) {
    _cache.remove(id);
    _cache[id] = entry;
  }

  Future<void> _ensureLoaded(Iterable<FogTileId> ids) async {
    final missing = ids.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    _addToCache(await storage.loadTiles(missing), missing);
  }

  /// Caches the tiles read from [storage] and marks the rest of [requested]
  /// as known to have no fog data, so they are not read again.
  void _addToCache(
    Iterable<StoredFogTile> stored,
    Iterable<FogTileId> requested,
  ) {
    for (final tile in stored) {
      _cache.putIfAbsent(
        tile.id,
        () => _CacheEntry(
          FogTileCodec.decode(tile.flag, tile.bytes),
          areaM2: tile.areaM2,
        ),
      );
    }
    for (final id in requested) {
      _cache.putIfAbsent(id, () => _CacheEntry(null));
    }
    _evict();
  }

  void _evict() {
    if (_cache.length <= maxCachedTiles) return;
    for (final id in _cache.keys.toList()) {
      if (_cache.length <= maxCachedTiles) break;
      final entry = _cache[id]!;
      if (entry.dirty || _pinned.contains(id)) continue;
      _cache.remove(id);
    }
  }

  Future<void> _flushIfNeeded() async {
    if (_dirty.length >= maxDirtyTiles) {
      await _flush();
    } else if (_dirty.isNotEmpty || _metaDirty) {
      _scheduleFlush();
    }
  }

  void _scheduleFlush() {
    if (_flushTimer != null || _disposed) return;
    _flushTimer = Timer(flushDelay, () {
      _flushTimer = null;
      flush().catchError((Object error) {
        debugPrint('Fog flush failed: $error');
      });
    });
  }

  /// Writes every modified tile and refreshes the pyramid above it.
  Future<void> flush() => _queue.run(_flush);

  Future<void> _flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_dirty.isEmpty && !_metaDirty) return;

    final timer = Stopwatch()..start();
    final baseDirty = _dirty.toSet();
    // The revision counts writes that change tiles; saving only the log
    // position does not make any tile newer.
    final nextRevision = _dirty.isEmpty ? _revision : _revision + 1;
    final changed = <FogTileId>{...baseDirty};
    final ancestors = <FogTileId>{};

    var level = baseDirty;
    for (var z = baseZoom; z > minZoom; z--) {
      final byParent = <FogTileId, List<FogTileId>>{};
      for (final id in level) {
        byParent.putIfAbsent(id.parent!, () => []).add(id);
      }
      _pinned.addAll(byParent.keys);
      await _ensureLoaded(byParent.keys);
      for (final group in byParent.entries) {
        final entry = _cache[group.key]!;
        final parentMask = entry.mask ??= FogMask();
        for (final child in group.value) {
          FogPyramid.downsampleInto(
            child: _cache[child]?.mask ?? FogMask(),
            parent: parentMask,
            quadX: child.x & 1,
            quadY: child.y & 1,
            overviewFloor: overviewFloor,
          );
        }
        entry.dirty = true;
      }
      ancestors.addAll(byParent.keys);
      level = byParent.keys.toSet();
    }
    changed.addAll(ancestors);

    var areaDelta = 0.0;
    final upserts = <StoredFogTile>[];
    final newAreas = <FogTileId, double>{};
    final ids = changed.toList();
    final List<EncodedFogTile> encoded;
    try {
      for (final id in ids) {
        _cache[id]!.mask!.quantizeInPlace(
          step: id.z == baseZoom
              ? FogConfig.baseQuantStep
              : FogConfig.overviewQuantStep,
        );
      }
      encoded = await _encodeAll([for (final id in ids) _cache[id]!.mask!]);
    } on Object {
      _pinned.removeAll(ancestors);
      rethrow;
    }
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      final entry = _cache[id]!;
      var area = 0.0;
      if (id.z == baseZoom) {
        area = _areaOf(id, entry.mask!);
        areaDelta += area - entry.areaM2;
        newAreas[id] = area;
      }
      upserts.add(
        StoredFogTile(
          id: id,
          flag: encoded[i].flag,
          rev: nextRevision,
          areaM2: area,
          bytes: encoded[i].bytes,
        ),
      );
    }

    final newTotal = math.max(0.0, _totalAreaM2 + areaDelta);
    try {
      await storage.commit(
        upserts: upserts,
        meta: {
          'rev': nextRevision.toDouble(),
          'totalAreaM2': newTotal,
          'lastAppliedLogId': _lastAppliedLogId.toDouble(),
          'baseZoom': baseZoom.toDouble(),
          'minZoom': minZoom.toDouble(),
          'formatVersion': FogTileCodec.formatVersion.toDouble(),
        },
      );
    } on Object {
      _pinned.removeAll(ancestors);
      rethrow;
    }

    _revision = nextRevision;
    _totalAreaM2 = newTotal;
    _metaDirty = false;
    for (final id in changed) {
      final entry = _cache[id];
      if (entry == null) continue;
      entry.dirty = false;
      final area = newAreas[id];
      if (area != null) entry.areaM2 = area;
    }
    _dirty.removeAll(baseDirty);
    _pinned.removeAll(ancestors);
    _evict();
    _lastFlushMillis = timer.elapsedMilliseconds;
    _lastFlushTiles = upserts.length;
    if (changed.isNotEmpty && !_changes.isClosed) {
      _changes.add(FogChange(changed, flushed: true));
    }
  }

  Future<List<EncodedFogTile>> _encodeAll(List<FogMask> masks) async {
    if (!encodeInIsolate || masks.length < isolateEncodeThreshold) {
      return [for (final mask in masks) FogTileCodec.encode(mask)];
    }
    final raw = [for (final mask in masks) mask.data];
    final workers = math.max(
      1,
      math.min(
        math.min(Platform.numberOfProcessors, 4),
        raw.length ~/ isolateEncodeThreshold,
      ),
    );
    final share = (raw.length / workers).ceil();
    final parts = await Future.wait([
      for (var start = 0; start < raw.length; start += share)
        () {
          final slice = raw.sublist(start, math.min(start + share, raw.length));
          return Isolate.run(() => _encodeBatch(slice));
        }(),
    ]);
    return [
      for (final part in parts)
        for (final item in part) EncodedFogTile(item.$1, item.$2),
    ];
  }

  double _areaOf(FogTileId id, FogMask mask) {
    final latitude = FogMercator.yToLat(
      (id.y + 0.5) * FogTileId.size,
      baseZoom,
    );
    final pixel = metersPerPixel(
      latitude: latitude,
      zoom: baseZoom.toDouble(),
    );
    return mask.coveredSum / 255.0 * pixel * pixel;
  }

  /// Draws many entries at once, optionally rasterizing in a background
  /// isolate (a separate thread of Dart code with its own memory).
  Future<void> importEntries(
    List<TrackLogEntry> entries, {
    bool useIsolate = true,
    int chunkSize = 2000,
    void Function(double progress)? onProgress,
  }) {
    return _queue.run(
      () => _import(entries, useIsolate, chunkSize, onProgress),
    );
  }

  Future<void> _import(
    List<TrackLogEntry> entries,
    bool useIsolate,
    int chunkSize,
    void Function(double progress)? onProgress,
  ) async {
    final parallel = useIsolate
        ? math.max(1, math.min(Platform.numberOfProcessors, 4))
        : 1;
    final groupSize = chunkSize * parallel;

    for (var start = 0; start < entries.length; start += groupSize) {
      final groupEnd = math.min(start + groupSize, entries.length);
      final chunks = <List<TrackLogEntry>>[];
      final jobs = <_ChunkJob>[];
      for (var from = start; from < groupEnd; from += chunkSize) {
        final chunk = entries.sublist(
          from,
          math.min(from + chunkSize, groupEnd),
        );
        chunks.add(chunk);
        jobs.add(_buildJob(chunk));
      }

      final results = useIsolate
          ? await Future.wait([
              for (final job in jobs) Isolate.run(() => _rasterizeChunk(job)),
            ])
          : [for (final job in jobs) _rasterizeChunk(job)];

      for (var i = 0; i < results.length; i++) {
        await _mergeChunk(chunks[i], results[i]);
      }
      await _flushIfNeeded();
      onProgress?.call(groupEnd / entries.length);
    }
  }

  /// Turns [chunk] into a job for [_rasterizeChunk] and remembers where each
  /// session ended, so the next chunk continues the same path.
  _ChunkJob _buildJob(List<TrackLogEntry> chunk) {
    final bySession = <String, List<TrackLogEntry>>{};
    for (final entry in chunk) {
      bySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }

    final paths = <_PathJob>[];
    final lastAnchors = <String, _Anchor>{};
    for (final session in bySession.entries) {
      final anchor = _lastPoint[session.key];
      final xy = <double>[];
      final radii = <double>[];
      if (anchor != null) {
        xy
          ..add(anchor.x)
          ..add(anchor.y);
        radii.add(anchor.radius);
      }
      for (final entry in session.value) {
        final x = FogMercator.lngToX(entry.longitude, baseZoom);
        final y = FogMercator.latToY(entry.latitude, baseZoom);
        final radius = metersToPixels(
          meters: radiusMeters,
          latitude: entry.latitude,
          zoom: baseZoom.toDouble(),
        );
        xy
          ..add(x)
          ..add(y);
        radii.add(radius);
        lastAnchors[session.key] = _Anchor(x, y, radius);
      }
      paths.add(
        _PathJob(
          Float64List.fromList(xy),
          Float64List.fromList(radii),
          continues: anchor != null,
        ),
      );
    }
    lastAnchors.forEach(_rememberAnchor);
    return _ChunkJob(
      baseZoom,
      _rasterizer.edgeWidth,
      _rasterizer.quantStep,
      paths,
    );
  }

  Future<void> _mergeChunk(
    List<TrackLogEntry> chunk,
    Map<int, Uint8List> result,
  ) async {
    final ids = [for (final key in result.keys) FogTileId.fromKey(key)];
    final changedIds = <FogTileId>{};
    _pinned.addAll(ids);
    try {
      await _ensureLoaded(ids);
      for (final id in ids) {
        final entry = _cache[id]!;
        _touch(id, entry);
        final incoming = FogMask.fromBytes(result[id.key]!);
        final existing = entry.mask;
        final bool changed;
        if (existing == null) {
          changed = !incoming.isEmpty;
          if (changed) entry.mask = incoming;
        } else {
          changed = existing.mergeMax(incoming);
        }
        if (!changed) continue;
        entry.dirty = true;
        _dirty.add(id);
        changedIds.add(id);
      }
    } finally {
      _pinned.removeAll(ids);
    }

    for (final entry in chunk) {
      _noteApplied(entry.id);
    }
    _appliedPoints += chunk.length;
    if (changedIds.isNotEmpty && !_changes.isClosed) {
      _changes.add(FogChange(changedIds));
    }
  }

  /// Draws the log entries newer than the last applied one, for example
  /// after a crash or after the tile format changed.
  Future<void> replayFrom(
    TrackLogStorage log, {
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) {
    return _catchUp(
      log,
      fromScratch: false,
      useIsolate: useIsolate,
      onProgress: onProgress,
    );
  }

  /// Throws the tiles away and draws the whole track log again.
  Future<void> rebuildFrom(
    TrackLogStorage log, {
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) {
    return _catchUp(
      log,
      fromScratch: true,
      useIsolate: useIsolate,
      onProgress: onProgress,
    );
  }

  Future<void> _catchUp(
    TrackLogStorage log, {
    required bool fromScratch,
    required bool useIsolate,
    void Function(double progress)? onProgress,
  }) async {
    _catchUps++;
    try {
      if (fromScratch) await clear();
      _behindLog = false;
      await _replay(log, useIsolate, onProgress);
    } on Object {
      _behindLog = true;
      rethrow;
    } finally {
      _catchUps--;
      if (_catchUps == 0) _applyDeferred();
    }
  }

  Future<void> _replay(
    TrackLogStorage log,
    bool useIsolate,
    void Function(double progress)? onProgress,
  ) async {
    final total = await log.count();
    var after = _lastAppliedLogId;
    var done = after;
    while (true) {
      final batch = await log.entriesAfter(after);
      if (batch.isEmpty) break;
      final previous = <TrackLogEntry>[];
      for (final session in batch.map((e) => e.sessionId).toSet()) {
        if (_lastPoint.containsKey(session)) continue;
        final last = await log.lastEntryOfSession(session, atOrBeforeId: after);
        if (last != null) previous.add(last);
      }
      await importEntries([...previous, ...batch], useIsolate: useIsolate);
      after = batch.last.id!;
      done += batch.length;
      if (total > 0) onProgress?.call(math.min(1, done / total));
    }
    await flush();
  }

  /// Declares every log entry up to [id] as handled, without drawing it.
  /// Used after clearing the fog on purpose so a restart does not redraw it.
  Future<void> markLogApplied(int id) {
    return _queue.run(() async {
      _behindLog = false;
      if (id > _lastAppliedLogId) _lastAppliedLogId = id;
      _metaDirty = true;
      await _flush();
    });
  }

  Future<void> clear() {
    return _queue.run(() async {
      _flushTimer?.cancel();
      _flushTimer = null;
      await storage.clear();
      _cache.clear();
      _dirty.clear();
      _pinned.clear();
      _lastPoint.clear();
      _revision = 0;
      _totalAreaM2 = 0;
      _lastAppliedLogId = 0;
      _metaDirty = false;
      if (!_changes.isClosed) _changes.add(const FogChange({}, all: true));
    });
  }

  /// Loads the tiles of a level range so [peek] can answer synchronously.
  Future<void> prepare(int z, int xMin, int xMax, int yMin, int yMax) async {
    final wanted = <FogTileId>[
      for (var x = xMin; x <= xMax; x++)
        for (var y = yMin; y <= yMax; y++) FogTileId(z, x, y),
    ];
    if (wanted.every(_cache.containsKey)) {
      for (final id in wanted) {
        _touch(id, _cache[id]!);
      }
      return;
    }
    final stored = await storage.loadRange(
      z: z,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
    );
    _addToCache(stored, wanted);
  }

  /// The decoded tile if it is cached, without any I/O.
  FogMask? peek(FogTileId id) => _cache[id]?.mask;

  bool isKnownAbsent(FogTileId id) {
    final entry = _cache[id];
    return entry != null && entry.mask == null;
  }

  Future<FogMask?> maskFor(FogTileId id) async {
    if (!_cache.containsKey(id)) await prepare(id.z, id.x, id.x, id.y, id.y);
    return _cache[id]?.mask;
  }

  Future<void> dispose() async {
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _changes.close();
  }
}
