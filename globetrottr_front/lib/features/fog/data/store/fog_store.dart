import 'dart:async';
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
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_replay_tracker.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_batch_drawing.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_writer.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

export 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';

/// The fog of one user as tiles of 8-bit coverage.
///
/// New positions are rasterized into tiles immediately and written to
/// [storage] in batches. Every write also refreshes the coarser pyramid
/// levels used when the map is zoomed out. The tiles are a cache: the
/// authoritative history is the track log, which can rebuild them.
///
/// Every operation that changes the fog runs through one queue, so they
/// never interleave.
class FogStore {
  FogStore._(
    this.storage, {
    required this.baseZoom,
    required this.minZoom,
    required this.radiusMeters,
    required this.maxCachedTiles,
    required this.maxDirtyTiles,
    required this.importTileBudget,
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
    int importTileBudget = FogConfig.importTileBudget,
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
      importTileBudget: importTileBudget,
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

  /// Base tiles one step of a batch import may touch. Each tile is 64 KB in
  /// memory, so this bounds the memory of imports and rebuilds no matter how
  /// long or fast the journey is.
  final int importTileBudget;
  final Duration flushDelay;
  final int overviewFloor;

  /// Compress large writes in a background isolate to keep the UI smooth.
  final bool encodeInIsolate;
  final int isolateEncodeThreshold;
  final FogRasterizer _rasterizer;

  late final FogTileCache _tiles = FogTileCache(
    storage,
    maxTiles: maxCachedTiles,
  );
  late final FogTileWriter _writer = FogTileWriter(
    _tiles,
    baseZoom: baseZoom,
    minZoom: minZoom,
    overviewFloor: overviewFloor,
    encodeInIsolate: encodeInIsolate,
    isolateEncodeThreshold: isolateEncodeThreshold,
  );
  late final FogImportPlanner _planner = FogImportPlanner(
    baseZoom: baseZoom,
    radiusMeters: radiusMeters,
    rasterizer: _rasterizer,
  );
  final FogLastPoints _lastPoints = FogLastPoints();
  final FogReplayTracker _replayTracker = FogReplayTracker();
  final StreamController<FogChange> _changes =
      StreamController<FogChange>.broadcast();

  final SerialQueue _queue = SerialQueue();
  Timer? _flushTimer;
  bool _metaDirty = false;
  bool _disposed = false;

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

  /// Completes when no replay or rebuild is running.
  Future<void> whenCaughtUp() => _replayTracker.whenIdle();

  FogStoreDiagnostics get diagnostics => FogStoreDiagnostics(
    cachedTiles: _tiles.length,
    dirtyTiles: _tiles.dirty.length,
    revision: _revision,
    totalAreaM2: _totalAreaM2,
    appliedPoints: _appliedPoints,
    lastApplyMicros: _lastApplyMicros,
    lastFlushMillis: _lastFlushMillis,
    lastFlushTiles: _lastFlushTiles,
    peakCachedTiles: _tiles.peak,
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
    if (_replayTracker.isRunning) {
      return _replayTracker.defer(
        FogDeferredPoint(sessionId, latitude, longitude, logId),
      );
    }
    return _queue.run(() => _apply(sessionId, latitude, longitude, logId));
  }

  /// Draws the points that waited for a replay. Those the replay already
  /// read from the log are skipped.
  void _applyDeferred(List<FogDeferredPoint> points) {
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
    final previous = _lastPoints[sessionId];
    final ax = previous?.x ?? x;
    final ay = previous?.y ?? y;

    final reach = radius + _rasterizer.edgeWidth;
    final needed = _tilesCovering(
      math.min(ax, x) - reach,
      math.max(ax, x) + reach,
      math.min(ay, y) - reach,
      math.max(ay, y) + reach,
    );
    _tiles.pinned.addAll(needed);
    try {
      await _tiles.ensureLoaded(needed);
      final created = <FogTileId>{};
      final changed = <FogTileId>{};
      _rasterizer.drawStadium(
        ax: ax,
        ay: ay,
        bx: x,
        by: y,
        radius: radius,
        maskFor: (id) => _tiles.maskToDrawInto(id, created),
        onChanged: changed.add,
      );
      _tiles.markDrawn(created, changed);
      _lastPoints.remember(sessionId, FogLastPoint(x, y, radius));
      _noteApplied(logId);
      if (changed.isNotEmpty && !_changes.isClosed) {
        _changes.add(FogChange(changed));
      }
    } finally {
      _tiles.pinned.removeAll(needed);
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

  Future<void> _flushIfNeeded() async {
    if (_tiles.dirty.length >= maxDirtyTiles) {
      await _flush();
    } else if (_tiles.dirty.isNotEmpty || _metaDirty) {
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
    if (_tiles.dirty.isEmpty && !_metaDirty) return;

    final timer = Stopwatch()..start();
    final result = await _writer.write(
      revision: _revision,
      totalAreaM2: _totalAreaM2,
      lastAppliedLogId: _lastAppliedLogId,
    );
    _revision = result.revision;
    _totalAreaM2 = result.totalAreaM2;
    _metaDirty = false;
    _lastFlushMillis = timer.elapsedMilliseconds;
    _lastFlushTiles = result.tiles.length;
    if (result.tiles.isNotEmpty && !_changes.isClosed) {
      _changes.add(FogChange(result.tiles, flushed: true));
    }
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
    // A path of this many base pixels touches at most about
    // importTileBudget / parallel tiles, so a whole step stays in budget.
    final pathBudget =
        math.max(1, importTileBudget ~/ parallel - 2) * FogTileId.size / 2;

    var start = 0;
    while (start < entries.length) {
      final chunks = <List<TrackLogEntry>>[];
      final jobs = <FogChunkJob>[];
      var from = start;
      while (chunks.length < parallel && from < entries.length) {
        final to = _planner.chunkEnd(entries, from, chunkSize, pathBudget);
        final chunk = entries.sublist(from, to);
        chunks.add(chunk);
        jobs.add(_planner.buildJob(chunk, _lastPoints));
        from = to;
      }

      final results = useIsolate
          ? await Future.wait([
              for (final job in jobs) Isolate.run(() => rasterizeChunk(job)),
            ])
          : [for (final job in jobs) rasterizeChunk(job)];
      for (var i = 0; i < results.length; i++) {
        await _mergeChunk(chunks[i], results[i]);
      }
      await _flushIfNeeded();
      start = from;
      onProgress?.call(start / entries.length);
    }
  }

  Future<void> _mergeChunk(
    List<TrackLogEntry> chunk,
    Map<int, Uint8List> result,
  ) async {
    final changed = await _tiles.mergeMasks(result);
    for (final entry in chunk) {
      _noteApplied(entry.id);
    }
    _appliedPoints += chunk.length;
    if (changed.isNotEmpty && !_changes.isClosed) {
      _changes.add(FogChange(changed));
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
    _replayTracker.begin();
    try {
      if (fromScratch) await clear();
      _behindLog = false;
      await _replay(log, useIsolate, onProgress);
    } on Object {
      _behindLog = true;
      rethrow;
    } finally {
      _applyDeferred(_replayTracker.end());
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
        if (_lastPoints.contains(session)) continue;
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
      _tiles.clear();
      _lastPoints.clear();
      _revision = 0;
      _totalAreaM2 = 0;
      _lastAppliedLogId = 0;
      _metaDirty = false;
      if (!_changes.isClosed) _changes.add(const FogChange({}, all: true));
    });
  }

  /// Loads the tiles of a level range so [peek] can answer synchronously.
  Future<void> prepare(int z, int xMin, int xMax, int yMin, int yMax) {
    return _tiles.loadRange(z, xMin, xMax, yMin, yMax);
  }

  /// The decoded tile if it is cached, without any I/O.
  FogMask? peek(FogTileId id) => _tiles.peek(id);

  bool isKnownAbsent(FogTileId id) => _tiles.isKnownAbsent(id);

  Future<FogMask?> maskFor(FogTileId id) async {
    if (!_tiles.contains(id)) await prepare(id.z, id.x, id.x, id.y, id.y);
    return _tiles.peek(id);
  }

  Future<void> dispose() async {
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _changes.close();
  }
}
