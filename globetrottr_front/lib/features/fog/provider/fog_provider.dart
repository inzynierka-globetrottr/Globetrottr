import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_cells.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/sqflite_fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:globetrottr_front/features/regions/data/regions_db_version.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

final fogTileStorageProvider = Provider<FogTileStorage>((ref) {
  final storage = SqfliteFogTileStorage();
  ref.onDispose(storage.close);
  return storage;
});

/// Owns the user's fog. It draws every logged position when the player reaches
/// it on the map, first catching up with whatever the track log holds that the
/// tiles do not yet (after a crash or a first start).
///
/// The state is the [FogTileSource] the map layer paints from.
class FogNotifier extends AsyncNotifier<FogTileSource> {
  FogStore? _store;
  bool _isReplaying = false;

  FogStore get _openStore {
    final store = _store;
    if (store == null) throw StateError('The fog is not ready yet');
    return store;
  }

  @override
  Future<FogTileSource> build() async {
    ref.listen(locationProvider.select((s) => s.isRecording), (
      previous,
      next,
    ) {
      final stopped = (previous ?? false) && !next;
      if (stopped) ref.read(playerMotionProvider).finish();
      _store?.endLivePath();
      if (stopped) unawaited(_flushQuietly());
    });

    final store = await FogStore.open(ref.read(fogTileStorageProvider));
    final source = FogTileSource(store);
    _store = store;

    final motion = ref.read(playerMotionProvider);
    final logged = motion.passed.listen((e) {
      store
          .applyPoint(
            sessionId: e.sessionId,
            latitude: e.latitude,
            longitude: e.longitude,
            logId: e.id,
          )
          .catchError((Object error) {
            debugPrint('Applying a position to the fog failed: $error');
          });
    });
    final storeChanges = store.changes.listen((change) {
      if (_isReplaying) return;
      if (change.areaDeltas.isNotEmpty) {
        final deltas = [
          for (final entry in change.areaDeltas.entries)
            TileAreaDelta(
              id: entry.key,
              areaDeltaM2: entry.value.total,
              cells: entry.value,
            ),
        ];
        if (deltas.isNotEmpty) {
          ref
              .read(statisticsTrackerProvider)
              .onTilesCommitted(deltas)
              .catchError((Object error) {
                debugPrint('Statistics tracking on tile commit failed: $error');
              });
        }
      }
    });
    final packs = ref
        .read(missingRegionPacksProvider)
        .stream
        .listen((code) => unawaited(_installRegions(code)));
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) return;
        motion.finish();
        unawaited(_flushQuietly());
      },
    );
    ref.onDispose(() {
      unawaited(logged.cancel());
      unawaited(storeChanges.cancel());
      unawaited(packs.cancel());
      lifecycle.dispose();
      source.dispose();
      _store = null;
      unawaited(store.dispose());
    });

    // The replay can take minutes after a long journey or a format change,
    // so the stored fog is shown at once and the rest is drawn in the
    // background (new positions wait for it inside the store).
    unawaited(_catchUp(store, ref.read(trackLogStorageProvider)));
    return source;
  }

  Future<void> _catchUp(FogStore store, TrackLogStorage log) async {
    _isReplaying = true;
    try {
      await store.replayFrom(log);
    } on Object catch (error) {
      // The stored tiles are still valid; the next start retries the replay.
      debugPrint('Replaying the track log into the fog failed: $error');
    } finally {
      _isReplaying = false;
      await _refreshStatistics();
    }
  }

  /// The cities of a country arrive the first time the user records there;
  /// the tiles recorded before are then attributed again. The statistics
  /// stay as they are until the rebuild replaces them.
  Future<void> _installRegions(String countryCode) async {
    try {
      if (!await ref.read(regionPackServiceProvider).ensurePack(countryCode)) {
        return;
      }
    } catch (e) {
      debugPrint('Installing the regions of $countryCode failed: $e');
      return;
    }
    await _forcedRebuild(keepVisits: true);
  }

  static const _builtWithKey = 'regions_version';
  static const _pendingKey = 'stats_rebuild_pending';

  /// Rebuilds after new bundled boundaries (their ids differ, so visit
  /// dates cannot be carried over) or after a rebuild that was cut short.
  /// Both are kept in `stats.db`, so a kill at any point retries.
  Future<void> _refreshStatistics() async {
    var boundariesChanged = false;
    var pending = false;
    try {
      final statsStorage = ref.read(statisticsStorageProvider);
      boundariesChanged =
          await statsStorage.getRecord(_builtWithKey) !=
          kBundledRegionsDbVersion.toDouble();
      pending = (await statsStorage.getRecord(_pendingKey) ?? 0) > 0;
    } catch (e) {
      debugPrint('Checking the statistics state failed: $e');
    }
    if (boundariesChanged || pending) {
      await _forcedRebuild(keepVisits: !boundariesChanged);
    } else {
      await backfillStatsIfEmpty();
    }
  }

  bool _rebuildWaiting = false;
  final _rebuilds = SerialQueue();

  /// Requests that arrive while a rebuild waits to start join it, so
  /// several country files installed at once cost one rebuild.
  Future<void> _forcedRebuild({required bool keepVisits}) async {
    if (_rebuildWaiting) return;
    _rebuildWaiting = true;
    await _rebuilds.run(() async {
      _rebuildWaiting = false;
      await backfillStatsIfEmpty(force: true, keepVisits: keepVisits);
    });
  }

  /// Rebuilds the region statistics from the stored tiles once, or every
  /// time when [force] is set; a forced rebuild starts from an empty tile
  /// cache and replaces the statistics in one step.
  Future<void> backfillStatsIfEmpty({
    bool force = false,
    bool keepVisits = true,
  }) async {
    try {
      final statsStorage = ref.read(statisticsStorageProvider);
      final isBackfilled = await statsStorage.getRecord('stats_backfilled');
      if (!force && isBackfilled != null && isBackfilled > 0) {
        return;
      }
      final allRegionStats = await statsStorage.getAllRegionStats();
      final hasAreaStats = allRegionStats.any((r) => r.discoveredAreaM2 > 0);
      if (!force && hasAreaStats) {
        await statsStorage.setRecordIfMax('stats_backfilled', 1.0);
        return;
      }
      if (force) await statsStorage.setRecord(_pendingKey, 1);

      final storage = ref.read(fogTileStorageProvider);
      final tiles = await storage.loadBaseTileAreas();
      await ref
          .read(statisticsTrackerProvider)
          .rebuildFromFogTiles(
            [
              for (final t in tiles)
                TileAreaDelta(id: t.id, areaDeltaM2: t.areaM2),
            ],
            loadCells: (ids) => loadCellAreas(storage, ids),
            keepVisits: keepVisits,
            resetTileCache: force,
          );
      await statsStorage.setRecordIfMax('stats_backfilled', 1.0);
      await statsStorage.setRecord(
        _builtWithKey,
        kBundledRegionsDbVersion.toDouble(),
      );
      if (force) await statsStorage.setRecord(_pendingKey, 0);
    } catch (e) {
      debugPrint('Backfilling stats from fog failed: $e');
    }
  }

  Future<void> flush() => _flushQuietly();

  Future<void> _flushQuietly() async {
    try {
      await _store?.flush();
    } on Object catch (error) {
      debugPrint('Fog flush failed: $error');
    }
  }

  /// Stores [entries] in the track log and draws them into the fog.
  Future<void> importEntries(
    List<TrackLogEntry> entries, {
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) async {
    final store = _openStore;
    final stored = await ref.read(trackLogStorageProvider).appendAll(entries);
    await store.importEntries(
      stored,
      useIsolate: useIsolate,
      onProgress: onProgress,
    );
    await store.flush();
  }

  /// Draws the whole track log again from scratch.
  Future<void> rebuild({
    bool useIsolate = true,
    void Function(double progress)? onProgress,
  }) async {
    _isReplaying = true;
    try {
      await _openStore.rebuildFrom(
        ref.read(trackLogStorageProvider),
        useIsolate: useIsolate,
        onProgress: onProgress,
      );
    } finally {
      _isReplaying = false;
      await backfillStatsIfEmpty(force: true);
    }
  }

  /// Removes the fog tiles but keeps the track log, so [rebuild] can bring
  /// the fog back.
  Future<void> clearFog() async {
    final store = _openStore;
    await store.clear();
    final newest = await ref.read(trackLogStorageProvider).lastId();
    await store.markLogApplied(newest);
    try {
      await ref.read(statisticsStorageProvider).clearRegionStats();
    } catch (_) {}
  }
}

final fogProvider = AsyncNotifierProvider<FogNotifier, FogTileSource>(
  FogNotifier.new,
);

class FogRenderOptionsNotifier extends Notifier<FogRenderOptions> {
  @override
  FogRenderOptions build() => const FogRenderOptions();

  // ignore: avoid_public_notifier_properties
  FogRenderOptions get options => state;

  set options(FogRenderOptions options) => state = options;
}

final fogRenderOptionsProvider =
    NotifierProvider<FogRenderOptionsNotifier, FogRenderOptions>(
      FogRenderOptionsNotifier.new,
    );
