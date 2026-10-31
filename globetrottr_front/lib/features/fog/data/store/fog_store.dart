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
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_replay_tracker.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_batch_drawing.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_writer.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_trail.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

export 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';

/// The fog of one user as tiles of 8-bit coverage.
///
/// A new position joins the [trail] at once and is rasterized into the tiles
/// in the queue; the tiles reach [storage] in batches. Every write also
/// refreshes the coarser pyramid levels used when the map is zoomed out. The
/// tiles are a cache: the authoritative history is the track log, which can
/// rebuild them.
///
/// Every operation that changes the fog runs through one queue, so they
/// never interleave.
class FogStore {
  FogStore._(
    this.storage, {
    required this.baseZoom,
    required this.maxSegmentMeters,
    required this.maxCachedTiles,
    required this.maxDirtyTiles,
    required this.importTileBudget,
    required this.flushDelay,
    required this.encodeInIsolate,
    required this.isolateEncodeThreshold,
    required this._rasterizer,
    required this._revision,
    required this._totalAreaM2,
    required this._lastAppliedLogId,
    required this._skippedLogEntries,
  });

  static Future<FogStore> open(
    FogTileStorage storage, {
    int baseZoom = FogConfig.baseZoom,
    double maxSegmentMeters = MapConfig.maxPathGapMeters,
    int maxCachedTiles = FogConfig.maxCachedTiles,
    int maxDirtyTiles = FogConfig.maxDirtyTiles,
    int importTileBudget = FogConfig.importTileBudget,
    Duration flushDelay = FogConfig.flushDelay,
    bool encodeInIsolate = true,
    int isolateEncodeThreshold = FogConfig.isolateEncodeThreshold,
  }) async {
    var meta = await storage.loadMeta();
    final expected = FogTileWriter.compatibilityMeta(baseZoom: baseZoom);
    final compatible =
        meta.isEmpty || expected.entries.every((e) => meta[e.key] == e.value);
    if (!compatible) {
      await storage.clear();
      meta = {};
    }
    return FogStore._(
      storage,
      baseZoom: baseZoom,
      maxSegmentMeters: maxSegmentMeters,
      maxCachedTiles: maxCachedTiles,
      maxDirtyTiles: maxDirtyTiles,
      importTileBudget: importTileBudget,
      flushDelay: flushDelay,
      encodeInIsolate: encodeInIsolate,
      isolateEncodeThreshold: isolateEncodeThreshold,
      rasterizer: FogRasterizer(
        zoom: baseZoom,
        quantStep: FogConfig.baseQuantStep,
      ),
      revision: meta['rev']?.toInt() ?? 0,
      totalAreaM2: meta['totalAreaM2'] ?? 0,
      lastAppliedLogId: meta['lastAppliedLogId']?.toInt() ?? 0,
      skippedLogEntries: meta['skippedLogEntries']?.toInt() ?? 0,
    );
  }

  final FogTileStorage storage;
  final int baseZoom;

  /// Longest stretch of one session drawn as a path; a longer gap between two
  /// points starts a new one (see [FogSegmentRule]).
  final double maxSegmentMeters;
  final int maxCachedTiles;
  final int maxDirtyTiles;

  /// Base tiles one step of a batch import may touch. Each tile is 64 KB in
  /// memory, so this bounds the memory of imports and rebuilds no matter how
  /// long or fast the journey is.
  final int importTileBudget;
  final Duration flushDelay;

  /// Compress large writes and decode large reads in a background isolate to
  /// keep the UI smooth.
  final bool encodeInIsolate;
  final int isolateEncodeThreshold;
  final FogRasterizer _rasterizer;

  late final FogTileCache _tiles = FogTileCache(
    storage,
    maxTiles: maxCachedTiles,
    decodeInIsolate: encodeInIsolate,
    isolateDecodeThreshold: isolateEncodeThreshold,
  );
  late final FogTileWriter _writer = FogTileWriter(
    _tiles,
    baseZoom: baseZoom,
    encodeInIsolate: encodeInIsolate,
    isolateEncodeThreshold: isolateEncodeThreshold,
  );
  late final FogSegmentRule _segmentRule = FogSegmentRule(
    radiusMeters: MapConfig.defaultVisionRadius,
    maxSegmentMeters: maxSegmentMeters,
  );
  late final FogImportPlanner _planner = FogImportPlanner(
    segmentRule: _segmentRule,
    rasterizer: _rasterizer,
  );
  final FogLastPoints _lastPoints = FogLastPoints();
  final FogTrail _trail = FogTrail();
  final FogReplayTracker _replayTracker = FogReplayTracker();
  final StreamController<FogChange> _changes =
      StreamController<FogChange>.broadcast();

  final SerialQueue _queue = SerialQueue();
  Timer? _flushTimer;
  bool _metaDirty = false;
  bool _disposed = false;

  /// True after a replay failed: the log holds entries that are not drawn,
  /// so new points must not move the log position past them.
  bool _behindLog = false;

  int _revision;
  double _totalAreaM2;
  int _lastAppliedLogId;
  int _skippedLogEntries;
  int _appliedPoints = 0;
  int _lastApplyMicros = 0;
  int _lastFlushMillis = 0;
  int _lastFlushTiles = 0;

  /// Newest segment of the trail already drawn into the tiles.
  int _appliedTrailId = 0;

  /// What was revealed since the last flush, for drawing over the images.
  FogTrail get trail => _trail;

  /// Whether the position continues the path from the newest drawn point,
  /// by the same rule as the tiles.
  bool joinsTrail(double latitude, double longitude) {
    final anchor = _trail.anchor;
    return anchor != null &&
        _segmentRule.connects(
          anchor,
          FogPathPoint.at(latitude, longitude, baseZoom),
        );
  }

  /// Recording stopped or started: the next position starts a new path.
  void endLivePath() => _trail.anchor = null;

  Stream<FogChange> get changes => _changes.stream;

  /// Completes when no replay or rebuild is running.
  @visibleForTesting
  Future<void> whenCaughtUp() => _replayTracker.whenIdle();

  FogStoreDiagnostics get diagnostics => FogStoreDiagnostics(
    cachedTiles: _tiles.length,
    dirtyTiles: _tiles.dirty.length,
    revision: _revision,
    totalAreaM2: _totalAreaM2,
    lastAppliedLogId: _lastAppliedLogId,
    appliedPoints: _appliedPoints,
    lastApplyMicros: _lastApplyMicros,
    lastFlushMillis: _lastFlushMillis,
    lastFlushTiles: _lastFlushTiles,
    peakCachedTiles: _tiles.peak,
    skippedLogEntries: _skippedLogEntries,
  );

  /// Draws the segment from the previous point of [sessionId] to this one.
  /// A session's first point is drawn as a disc. [logId] is the track log id
  /// of the point, used to resume after a crash.
  ///
  /// The point joins the trail before this returns, so the frame that calls
  /// it already shows it; the tiles follow in the queue.
  ///
  /// During a replay or rebuild the point is drawn only after it finished,
  /// so log entries always reach the tiles in log order.
  Future<void> applyPoint({
    required String sessionId,
    required double latitude,
    required double longitude,
    int? logId,
  }) {
    final point = FogPathPoint.at(latitude, longitude, baseZoom);
    final trailId = _trail.add(sessionId, point, _segmentRule);
    if (_replayTracker.isRunning) {
      return _replayTracker.defer(
        FogDeferredPoint(sessionId, point, logId, trailId),
      );
    }
    return _queue.run(() => _apply(sessionId, point, logId, trailId));
  }

  /// Draws the points that waited for a replay. Those the replay already
  /// read from the log are skipped.
  void _applyDeferred(List<FogDeferredPoint> points) {
    for (final point in points) {
      point.done.complete(
        _queue.run(() async {
          final logId = point.logId;
          if (logId != null && logId <= _lastAppliedLogId) {
            _appliedTrailId = point.trailId;
            await _flushIfNeeded();
            return;
          }
          await _apply(point.sessionId, point.point, logId, point.trailId);
        }),
      );
    }
  }

  Future<void> _apply(
    String sessionId,
    FogPathPoint point,
    int? logId,
    int trailId,
  ) async {
    final timer = Stopwatch()..start();
    final last = _lastPoints[sessionId];
    final start = last != null && _segmentRule.connects(last, point)
        ? last
        : point;

    final needed = _rasterizer
        .tilesFor(
          ax: start.x,
          ay: start.y,
          bx: point.x,
          by: point.y,
          radius: point.radius,
        )
        .ids
        .toList();
    await _tiles.withPinned(needed, () async {
      await _tiles.ensureLoaded(needed);
      final created = <FogTileId>{};
      final changed = <FogTileId>{};
      _rasterizer.drawStadium(
        ax: start.x,
        ay: start.y,
        bx: point.x,
        by: point.y,
        radius: point.radius,
        maskFor: (id) => _tiles.maskToDrawInto(id, created),
        onChanged: changed.add,
      );
      _tiles.markDrawn(created, changed);
      _lastPoints.remember(sessionId, point);
      _noteApplied(logId);
      _appliedTrailId = trailId;
      if (changed.isNotEmpty) _emit(FogChange(changed, onTrail: true));
    });
    _appliedPoints++;
    _lastApplyMicros = timer.elapsedMicroseconds;
    await _flushIfNeeded();
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
    } else if (_tiles.dirty.isNotEmpty || _metaDirty || !_trail.isEmpty) {
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
    final drawn = _appliedTrailId;
    if (_tiles.dirty.isEmpty && !_metaDirty) {
      _trail.forget(drawn);
      return;
    }

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
    if (result.tiles.isEmpty || _changes.isClosed || !_changes.hasListener) {
      _trail.forget(drawn);
    }
    if (result.tiles.isNotEmpty) {
      _emit(FogChange(result.tiles, trailWrittenUpTo: drawn));
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
    final parallel = useIsolate ? FogConfig.isolateWorkers : 1;
    // A path of this many base pixels touches at most about
    // importTileBudget / parallel tiles, so a whole step stays in budget.
    final pathBudget =
        math.max(1, importTileBudget ~/ parallel - 2) * FogTileId.size / 2;

    var start = 0;
    while (start < entries.length) {
      final chunks = <List<TrackLogEntry>>[];
      final jobs = <FogChunkJob>[];
      // Takes effect only after the step is drawn, so a failed step can be
      // repeated from where the path really ends.
      final lastPoints = _lastPoints.copy();
      var from = start;
      while (chunks.length < parallel && from < entries.length) {
        final to = _planner.chunkEnd(entries, from, chunkSize, pathBudget);
        final chunk = entries.sublist(from, to);
        chunks.add(chunk);
        jobs.add(_planner.buildJob(chunk, lastPoints));
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
      _lastPoints.adopt(lastPoints);
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
    if (changed.isNotEmpty) _emit(FogChange(changed));
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
    final meta = await storage.loadMeta();
    final markedAfter = meta['replayStepAfter']?.toInt();
    final markedAttempts = meta['replayAttempts']?.toInt() ?? 0;
    var after = _lastAppliedLogId;
    var done = after;
    var stitch = true;
    while (true) {
      // A step that was started before and never finished is retried in a
      // small size, and skipped once it failed too often.
      final failedBefore = markedAfter == after ? markedAttempts : 0;
      final batch = failedBefore > 0
          ? await log.entriesAfter(after, limit: FogConfig.retryStepEntries)
          : await log.entriesAfter(after);
      if (batch.isEmpty) break;

      if (failedBefore >= FogConfig.maxReplayStepAttempts) {
        await _skipEntries(batch);
        stitch = false;
      } else {
        await _markReplayStep(after, failedBefore + 1);
        final previous = <TrackLogEntry>[];
        for (final session in batch.map((e) => e.sessionId).toSet()) {
          if (!stitch || _lastPoints.contains(session)) continue;
          final last = await log.lastEntryOfSession(
            session,
            atOrBeforeId: after,
          );
          if (last != null) previous.add(last);
        }
        await importEntries([...previous, ...batch], useIsolate: useIsolate);
        await _markReplayStep(after, 0);
        stitch = true;
      }
      after = batch.last.id!;
      done += batch.length;
      if (total > 0) onProgress?.call(math.min(1, done / total));
    }
    await flush();
  }

  Future<void> _saveMeta(Map<String, double> meta) {
    return storage.commit(
      upserts: const [],
      meta: {
        ...FogTileWriter.compatibilityMeta(baseZoom: baseZoom),
        ...meta,
      },
    );
  }

  Future<void> _markReplayStep(int after, int attempts) {
    return _queue.run(
      () => _saveMeta({
        'replayStepAfter': after.toDouble(),
        'replayAttempts': attempts.toDouble(),
      }),
    );
  }

  /// Gives up on [entries]: they count as handled, so a restart does not
  /// try them again. A rebuild from the track log draws them.
  Future<void> _skipEntries(List<TrackLogEntry> entries) {
    return _queue.run(() async {
      debugPrint(
        'Skipping ${entries.length} track log entries that keep failing '
        'to replay (ids ${entries.first.id}..${entries.last.id})',
      );
      _noteApplied(entries.last.id);
      _skippedLogEntries += entries.length;
      await _flush();
      await _saveMeta({
        'skippedLogEntries': _skippedLogEntries.toDouble(),
        'replayAttempts': 0,
      });
    });
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
      _trail.clear();
      _revision = 0;
      _totalAreaM2 = 0;
      _lastAppliedLogId = 0;
      _skippedLogEntries = 0;
      _metaDirty = false;
      _emit(const FogChange({}, all: true));
    });
  }

  /// Loads the tiles of [range] so [peek] can answer synchronously.
  Future<void> prepare(FogTileRange range) => _tiles.loadRange(range);

  /// The decoded tile if it is cached, without any I/O.
  FogMask? peek(FogTileId id) => _tiles.peek(id);

  bool isKnownAbsent(FogTileId id) => _tiles.isKnownAbsent(id);

  Future<void> dispose() async {
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _changes.close();
  }
}
