import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/fog/data/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/sqflite_fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

final fogTileStorageProvider = Provider<FogTileStorage>((ref) {
  final storage = SqfliteFogTileStorage();
  ref.onDispose(storage.close);
  return storage;
});

/// Owns the user's fog. It draws every position the location service logs,
/// first catching up with whatever the track log holds that the tiles do not
/// yet (after a crash or a first start).
///
/// The state is the [FogTileSource] the map layer paints from.
class FogNotifier extends AsyncNotifier<FogTileSource> {
  FogStore? _store;

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
      if ((previous ?? false) && !next) unawaited(_flushQuietly());
    });

    final store = await FogStore.open(ref.read(fogTileStorageProvider));
    final source = FogTileSource(store);
    _store = store;

    final logged = ref.read(locationServiceProvider).loggedPoints.listen((e) {
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

    // The replay can take minutes after a long journey or a format change,
    // so the stored fog is shown at once and the rest is drawn in the
    // background (new positions wait for it inside the store).
    unawaited(_catchUp(store, ref.read(trackLogStorageProvider)));
    return source;
  }

  Future<void> _catchUp(FogStore store, TrackLogStorage log) async {
    try {
      await store.replayFrom(log);
    } on Object catch (error) {
      // The stored tiles are still valid; the next start retries the replay.
      debugPrint('Replaying the track log into the fog failed: $error');
    }
  }

  Future<void> _flushQuietly() async {
    try {
      await _store?.flush();
    } on Object catch (error) {
      debugPrint('Fog flush failed: $error');
    }
  }

  Future<void> flush() => _openStore.flush();

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
  }) {
    return _openStore.rebuildFrom(
      ref.read(trackLogStorageProvider),
      useIsolate: useIsolate,
      onProgress: onProgress,
    );
  }

  /// Removes the fog tiles but keeps the track log, so [rebuild] can bring
  /// the fog back.
  Future<void> clearFog() async {
    final store = _openStore;
    await store.clear();
    final newest = await ref.read(trackLogStorageProvider).lastId();
    await store.markLogApplied(newest);
  }
}

final fogProvider = AsyncNotifierProvider<FogNotifier, FogTileSource>(
  FogNotifier.new,
);

class FogRenderOptionsNotifier extends Notifier<FogRenderOptions> {
  @override
  FogRenderOptions build() => const FogRenderOptions();

  FogRenderOptions get options => state;

  set options(FogRenderOptions options) => state = options;
}

final fogRenderOptionsProvider =
    NotifierProvider<FogRenderOptionsNotifier, FogRenderOptions>(
      FogRenderOptionsNotifier.new,
    );
