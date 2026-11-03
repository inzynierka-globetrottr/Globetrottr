import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/sqflite_fog_tile_storage.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';

final heatTileStorageProvider = Provider<FogTileStorage>((ref) {
  final storage = SqfliteFogTileStorage(fileName: 'heat.db');
  ref.onDispose(storage.close);
  return storage;
});

/// Owns the user's heatmap. Nothing is computed until the heatmap is first
/// shown: it then counts what the track log holds that its tiles do not yet
/// (shown while it runs), and from then on every position the player
/// passes, like the fog.
///
/// The state is the tile source the map layer paints from.
class HeatmapNotifier extends AsyncNotifier<HeatTileSource> {
  HeatStore? _store;

  HeatStore get _openStore {
    final store = _store;
    if (store == null) throw StateError('The heatmap is not ready yet');
    return store;
  }

  @override
  Future<HeatTileSource> build() async {
    final store = await HeatStore.open(ref.read(heatTileStorageProvider));
    final source = HeatTileSource(store);
    _store = store;

    final logged = ref.read(playerMotionProvider).passed.listen((e) {
      store
          .applyPoint(
            sessionId: e.sessionId,
            latitude: e.latitude,
            longitude: e.longitude,
            logId: e.id,
          )
          .catchError((Object error) {
            debugPrint('Applying a position to the heatmap failed: $error');
          });
    });
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) unawaited(_flushQuietly());
      },
    );
    ref.onDispose(() {
      unawaited(logged.cancel());
      lifecycle.dispose();
      source.dispose();
      _store = null;
      unawaited(store.dispose());
    });

    unawaited(catchUp());
    return source;
  }

  /// Counts the track log entries the tiles do not hold yet, for example
  /// after the log was written without the heatmap open.
  Future<void> catchUp({void Function(double progress)? onProgress}) async {
    try {
      await _openStore.replayFrom(
        ref.read(trackLogStorageProvider),
        onProgress: onProgress,
      );
    } on Object catch (error) {
      // The stored tiles are still valid; the next catch-up retries.
      debugPrint('Replaying the track log into the heatmap failed: $error');
    }
  }

  Future<void> _flushQuietly() async {
    try {
      await _store?.flush();
    } on Object catch (error) {
      debugPrint('Heatmap flush failed: $error');
    }
  }

  /// Counts the whole track log again from scratch.
  Future<void> rebuild({void Function(double progress)? onProgress}) {
    return _openStore.rebuildFrom(
      ref.read(trackLogStorageProvider),
      onProgress: onProgress,
    );
  }

  /// Removes the heatmap tiles but keeps the track log, so [rebuild] can
  /// bring them back.
  Future<void> clear() async {
    final store = _openStore;
    await store.clear();
    final newest = await ref.read(trackLogStorageProvider).lastId();
    await store.markLogApplied(newest);
  }
}

final heatmapProvider = AsyncNotifierProvider<HeatmapNotifier, HeatTileSource>(
  HeatmapNotifier.new,
);
