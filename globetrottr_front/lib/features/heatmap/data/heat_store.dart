import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_rasterizer.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_layer.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_batch_drawing.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_replay_tracker.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_writer.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_session_tag.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_tile_cache.dart';
import 'package:globetrottr_front/features/heatmap/heat_config.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

class HeatStoreDiagnostics {
  const HeatStoreDiagnostics({
    required this.cachedTiles,
    required this.peakCachedTiles,
    required this.dirtyTiles,
    required this.lastAppliedLogId,
    required this.appliedPoints,
    required this.lastApplyMicros,
    required this.lastFlushMillis,
    required this.lastFlushTiles,
  });

  final int cachedTiles;
  final int peakCachedTiles;
  final int dirtyTiles;

  /// Id of the newest track log entry already counted.
  final int lastAppliedLogId;
  final int appliedPoints;
  final int lastApplyMicros;
  final int lastFlushMillis;
  final int lastFlushTiles;
}

/// Masks of one session rasterized in a background isolate.
List<Map<int, Uint8List>> _rasterizeSessions(List<FogChunkJob> jobs) {
  return [for (final job in jobs) rasterizeChunk(job)];
}

/// The heatmap of one user: per pixel, the number of sessions that passed
/// it, in the fog's tile pyramid (coarser levels keep the busiest pixel).
///
/// A pass is the fog's own stadium of the vision radius, so the heatmap
/// covers exactly what the fog reveals. Every pixel remembers the session
/// that last counted it, which keeps going back and forth, standing still and
/// replays after a restart from counting a session twice.
///
/// Like the fog, the tiles are a cache of the track log: they record the
/// last log entry they hold and can be rebuilt from scratch. Every operation
/// that changes them runs through one queue.
class HeatStore implements FogTileLayer {
  HeatStore._(
    this.storage, {
    required this.baseZoom,
    required this.radiusMeters,
    required this.maxCachedTiles,
    required this.maxDirtyTiles,
    required this.importTileBudget,
    required this.flushDelay,
    required this.encodeInIsolate,
    required this._lastAppliedLogId,
  });

  static Future<HeatStore> open(
    FogTileStorage storage, {
    int baseZoom = FogConfig.baseZoom,
    double radiusMeters = HeatConfig.radiusMeters,
    int maxCachedTiles = HeatConfig.maxCachedTiles,
    int maxDirtyTiles = HeatConfig.maxDirtyTiles,
    int importTileBudget = HeatConfig.importTileBudget,
    Duration flushDelay = HeatConfig.flushDelay,
    bool encodeInIsolate = true,
  }) async {
    var meta = await storage.loadMeta();
    final expected = compatibilityMeta(
      baseZoom: baseZoom,
      radiusMeters: radiusMeters,
    );
    final compatible =
        meta.isEmpty || expected.entries.every((e) => meta[e.key] == e.value);
    if (!compatible) {
      await storage.clear();
      meta = {};
    }
    return HeatStore._(
      storage,
      baseZoom: baseZoom,
      radiusMeters: radiusMeters,
      maxCachedTiles: maxCachedTiles,
      maxDirtyTiles: maxDirtyTiles,
      importTileBudget: importTileBudget,
      flushDelay: flushDelay,
      encodeInIsolate: encodeInIsolate,
      lastAppliedLogId: meta['lastAppliedLogId']?.toInt() ?? 0,
    );
  }

  /// What [open] checks to know the tiles were counted the way this build
  /// counts them. Every metadata write includes it.
  static Map<String, double> compatibilityMeta({
    required int baseZoom,
    required double radiusMeters,
  }) => {
    'baseZoom': baseZoom.toDouble(),
    'minZoom': FogConfig.minZoom.toDouble(),
    'drawVersion': FogConfig.drawVersion.toDouble(),
    'heatVersion': HeatConfig.algorithmVersion.toDouble(),
    'radiusMeters': radiusMeters,
  };

  /// The trail segment a deferred point belongs to: the heatmap has no trail.
  static const int _noTrailSegment = 0;

  final FogTileStorage storage;
  @override
  final int baseZoom;

  /// Half the width of a pass. The vision radius makes the heatmap cover
  /// exactly what the fog reveals; a smaller one draws the routes thinner.
  final double radiusMeters;
  final int maxCachedTiles;
  final int maxDirtyTiles;
  final int importTileBudget;
  final Duration flushDelay;
  final bool encodeInIsolate;

  late final HeatTileCache _tiles = HeatTileCache(
    storage,
    maxTiles: maxCachedTiles,
    decodeInIsolate: encodeInIsolate,
  );
  late final TileWriter<HeatTile> _writer = TileWriter(
    _tiles,
    const HeatTileKind(),
    baseZoom: baseZoom,
    encodeInIsolate: encodeInIsolate,
    isolateEncodeThreshold: FogConfig.isolateEncodeThreshold,
  );
  late final FogRasterizer _rasterizer = FogRasterizer(zoom: baseZoom);
  late final FogSegmentRule _segmentRule = FogSegmentRule(
    radiusMeters: radiusMeters,
    maxSegmentMeters: MapConfig.maxPathGapMeters,
  );
  late final FogImportPlanner _planner = FogImportPlanner(
    segmentRule: _segmentRule,
    rasterizer: _rasterizer,
    radiusMeters: radiusMeters,
  );
  final FogLastPoints _lastPoints = FogLastPoints();
  final FogReplayTracker _replayTracker = FogReplayTracker();
  final StreamController<FogChange> _changes =
      StreamController<FogChange>.broadcast();
  final SerialQueue _queue = SerialQueue();

  /// Empty masks one live point is rasterized into, reused between points.
  final List<FogMask> _scratch = [];

  Timer? _flushTimer;
  bool _metaDirty = false;
  bool _disposed = false;

  /// True after a replay failed: the log holds entries that are not counted,
  /// so new points must not move the log position past them.
  bool _behindLog = false;

  int _lastAppliedLogId;
  int _appliedPoints = 0;
  int _lastApplyMicros = 0;
  int _lastFlushMillis = 0;
  int _lastFlushTiles = 0;

  @override
  Stream<FogChange> get changes => _changes.stream;

  HeatStoreDiagnostics get diagnostics => HeatStoreDiagnostics(
    cachedTiles: _tiles.length,
    peakCachedTiles: _tiles.peak,
    dirtyTiles: _tiles.dirty.length,
    lastAppliedLogId: _lastAppliedLogId,
    appliedPoints: _appliedPoints,
    lastApplyMicros: _lastApplyMicros,
    lastFlushMillis: _lastFlushMillis,
    lastFlushTiles: _lastFlushTiles,
  );

  /// Counts the pass from the previous point of [sessionId] to this one.
  /// During a replay the point waits for it, so log entries are counted in
  /// log order.
  Future<void> applyPoint({
    required String sessionId,
    required double latitude,
    required double longitude,
    int? logId,
  }) {
    final point = FogPathPoint.at(
      latitude,
      longitude,
      baseZoom,
      radiusMeters: radiusMeters,
    );
    if (_replayTracker.isRunning) {
      return _replayTracker.defer(
        FogDeferredPoint(sessionId, point, logId, _noTrailSegment),
      );
    }
    return _queue.run(() => _apply(sessionId, point, logId));
  }

  void _applyDeferred(List<FogDeferredPoint> points) {
    for (final point in points) {
      point.done.complete(
        _queue.run(() async {
          final logId = point.logId;
          if (logId != null && logId <= _lastAppliedLogId) return;
          await _apply(point.sessionId, point.point, logId);
        }),
      );
    }
  }

  Future<void> _apply(String sessionId, FogPathPoint point, int? logId) async {
    final timer = Stopwatch()..start();
    final last = _lastPoints[sessionId];
    final start = last != null && _segmentRule.connects(last, point)
        ? last
        : point;

    final masks = <FogTileId, FogMask>{};
    _rasterizer.drawStadium(
      ax: start.x,
      ay: start.y,
      bx: point.x,
      by: point.y,
      radius: point.radius,
      maskFor: (id) => masks.putIfAbsent(
        id,
        () => _scratch.isEmpty ? FogMask() : _scratch.removeLast(),
      ),
    );
    final changed = await _count(
      HeatSessionTag.of(sessionId),
      {for (final e in masks.entries) e.key: e.value.data},
    );
    for (final mask in masks.values) {
      mask.data.fillRange(0, FogMask.pixels, 0);
      _scratch.add(mask);
    }
    _lastPoints.remember(sessionId, point);
    _noteApplied(logId);
    _appliedPoints++;
    _lastApplyMicros = timer.elapsedMicroseconds;
    if (changed.isNotEmpty) _emit(FogChange(changed));
    await _flushIfNeeded();
  }

  /// Counts one session's coverage into the base tiles; returns the tiles
  /// that changed.
  Future<Set<FogTileId>> _count(int tag, Map<FogTileId, Uint8List> coverage) {
    final ids = coverage.keys.toList();
    return _tiles.withPinned(ids, () async {
      await _tiles.ensureLoaded(ids);
      final changed = <FogTileId>{};
      for (final id in ids) {
        if (_tiles.baseTile(id).countSession(coverage[id]!, tag)) {
          changed.add(id);
        }
      }
      _tiles.dirty.addAll(changed);
      return changed;
    });
  }

  void _emit(FogChange change) {
    if (!_changes.isClosed) _changes.add(change);
  }

  void _noteApplied(int? logId) {
    if (_behindLog) return;
    if (logId != null && logId > _lastAppliedLogId) {
      _lastAppliedLogId = logId;
      _metaDirty = true;
    }
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
        debugPrint('Heatmap flush failed: $error');
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
      revision: 0,
      meta: (_) => {
        'lastAppliedLogId': _lastAppliedLogId.toDouble(),
        ...compatibilityMeta(baseZoom: baseZoom, radiusMeters: radiusMeters),
      },
    );
    _metaDirty = false;
    _lastFlushMillis = timer.elapsedMilliseconds;
    _lastFlushTiles = result.tiles.length;
    if (result.tiles.isNotEmpty) {
      _emit(FogChange(result.tiles, written: true));
    }
  }

  /// Counts many entries at once, rasterizing in background isolates.
  Future<void> importEntries(
    List<TrackLogEntry> entries, {
    bool useIsolate = true,
    int chunkSize = 2000,
  }) {
    return _queue.run(() => _import(entries, useIsolate, chunkSize));
  }

  Future<void> _import(
    List<TrackLogEntry> entries,
    bool useIsolate,
    int chunkSize,
  ) async {
    final parallel = useIsolate ? FogConfig.isolateWorkers : 1;
    // A path of this many base pixels touches at most about
    // importTileBudget / parallel tiles, so a whole step stays in budget.
    final pathBudget =
        math.max(1, importTileBudget ~/ parallel - 2) * FogTileId.size / 2;

    var start = 0;
    while (start < entries.length) {
      final chunks = <List<FogChunkJob>>[];
      final tags = <List<int>>[];
      final lastPoints = _lastPoints.copy();
      var from = start;
      while (chunks.length < parallel && from < entries.length) {
        final to = _planner.chunkEnd(entries, from, chunkSize, pathBudget);
        // Runs of one session in log order, not whole sessions: a session
        // that comes back after another one counts again, as it does live.
        final runs = <List<TrackLogEntry>>[];
        for (final entry in entries.sublist(from, to)) {
          if (runs.isEmpty || runs.last.first.sessionId != entry.sessionId) {
            runs.add([]);
          }
          runs.last.add(entry);
        }
        chunks.add([
          for (final run in runs) _planner.buildJob(run, lastPoints),
        ]);
        tags.add([
          for (final run in runs) HeatSessionTag.of(run.first.sessionId),
        ]);
        from = to;
      }

      final results = useIsolate
          ? await Future.wait([
              for (final jobs in chunks)
                Isolate.run(() => _rasterizeSessions(jobs)),
            ])
          : [for (final jobs in chunks) _rasterizeSessions(jobs)];
      final changed = <FogTileId>{};
      for (var c = 0; c < results.length; c++) {
        for (var s = 0; s < results[c].length; s++) {
          changed.addAll(
            await _count(tags[c][s], {
              for (final e in results[c][s].entries)
                FogTileId.fromKey(e.key): e.value,
            }),
          );
        }
      }
      for (var i = start; i < from; i++) {
        _noteApplied(entries[i].id);
      }
      _appliedPoints += from - start;
      _lastPoints.adopt(lastPoints);
      if (changed.isNotEmpty) _emit(FogChange(changed));
      await _flushIfNeeded();
      start = from;
    }
  }

  /// Counts the log entries newer than the last counted one.
  Future<void> replayFrom(
    TrackLogStorage log, {
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) {
    return _catchUp(log, false, useIsolate, onProgress);
  }

  /// Throws the tiles away and counts the whole track log again.
  Future<void> rebuildFrom(
    TrackLogStorage log, {
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) {
    return _catchUp(log, true, useIsolate, onProgress);
  }

  /// Completes when no replay or rebuild is running.
  Future<void> whenCaughtUp() => _replayTracker.whenIdle();

  Future<void> _catchUp(
    TrackLogStorage log,
    bool fromScratch,
    bool useIsolate,
    void Function(double progress)? onProgress,
  ) async {
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
      // A session that was already being counted continues from its last
      // counted point; its tag keeps that point from counting again.
      final previous = <TrackLogEntry>[];
      for (final session in batch.map((e) => e.sessionId).toSet()) {
        if (_lastPoints.contains(session)) continue;
        final last = await log.lastEntryOfSession(
          session,
          atOrBeforeId: after,
        );
        if (last != null) previous.add(last);
      }
      await importEntries([...previous, ...batch], useIsolate: useIsolate);
      after = batch.last.id!;
      done += batch.length;
      if (total > 0) onProgress?.call(math.min(1, done / total));
    }
    await flush();
  }

  /// Declares every log entry up to [id] as counted, without counting it.
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
      _lastAppliedLogId = 0;
      _metaDirty = false;
      _emit(const FogChange({}, all: true));
    });
  }

  @override
  Future<void> prepare(FogTileRange range) => _tiles.loadRange(range);

  @override
  FogMask? peek(FogTileId id) => _tiles.peek(id)?.counts;

  @override
  bool isKnownAbsent(FogTileId id) => _tiles.isKnownAbsent(id);

  Future<void> dispose() async {
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _changes.close();
  }
}
