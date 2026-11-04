import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

import '../../../support/fake_location_service.dart';
import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_track_log_storage.dart';

class _BackfilledStatistics extends Fake implements StatisticsStorage {
  @override
  Future<double?> getRecord(String key) async =>
      key == 'stats_backfilled' ? 1 : null;

  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => [];
}

class _CountingTracker extends Fake implements StatisticsTracker {
  int rebuilds = 0;

  @override
  Future<void> rebuildFromFogTiles(Iterable<TileAreaDelta> tiles) async {
    rebuilds++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  group('FogNotifier', () {
    test('startup does not rebuild statistics once backfilled', () async {
      await env.tiles.commit(
        upserts: [
          const StoredFogTile(
            id: FogTileId(15, 18197, 11098),
            flag: 1,
            rev: 1,
            areaM2: 5000,
          ),
        ],
        meta: const {},
      );
      final tracker = _CountingTracker();

      for (var start = 0; start < 2; start++) {
        final container = ProviderContainer(
          overrides: [
            ...env.overrides,
            statisticsStorageProvider.overrideWithValue(
              _BackfilledStatistics(),
            ),
            statisticsTrackerProvider.overrideWithValue(tracker),
          ],
        );
        final source = await container.read(fogProvider.future);
        await source.store.whenCaughtUp();
        await pumpEventQueue();
        container.dispose();
      }

      expect(tracker.rebuilds, 0);
    });

    test('draws the existing track log when it starts', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);

      final source = await container.read(fogProvider.future);

      await source.store.whenCaughtUp();

      final middle = offsetMeters(krakowLat, krakowLng, east: 100);
      expect(
        await coverageAt(source.store, middle.lat, middle.lng),
        1,
      );
    });

    test('draws points as they are logged', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      await source.store.whenCaughtUp();

      final entries = await env.log.appendAll(walkEast('live', points: 12));
      for (final entry in entries) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      await source.store.flush();

      const expected = 2 * 50 * 110 + math.pi * 50 * 50;
      expect(
        source.store.diagnostics.totalAreaM2,
        closeTo(expected, expected * 0.04),
      );
      expect(source.store.diagnostics.lastAppliedLogId, entries.last.id);
    });

    test('flushes the fog when recording stops', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      await source.store.whenCaughtUp();
      final notifier = container.read(locationProvider.notifier);
      await notifier.setRecording(true);
      final entries = await env.log.appendAll(walkEast('live', points: 5));
      for (final entry in entries) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      expect(source.store.diagnostics.revision, 0);

      await notifier.setRecording(false);
      await pumpEventQueue();
      await source.store.flush();

      expect(source.store.diagnostics.revision, 1);
    });

    test('recovers after a restart without duplicating anything', () async {
      final first = env.createContainer();
      final source = await first.read(fogProvider.future);
      await source.store.whenCaughtUp();
      final entries = await env.log.appendAll(walkEast('a', points: 30));
      for (final entry in entries.take(10)) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      await source.store.flush();
      final after10 = source.store.diagnostics.totalAreaM2;
      expect(after10, greaterThan(0));
      first.dispose();

      final second = env.createContainer();
      addTearDown(second.dispose);
      final restarted = await second.read(fogProvider.future);
      await restarted.store.whenCaughtUp();

      const expected = 2 * 50 * 290 + math.pi * 50 * 50;
      expect(
        restarted.store.diagnostics.totalAreaM2,
        closeTo(expected, expected * 0.04),
      );
      expect(restarted.store.diagnostics.lastAppliedLogId, entries.last.id);
    });

    test('imports entries and keeps them in the fog', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      await (await container.read(fogProvider.future)).store.whenCaughtUp();
      final notifier = container.read(fogProvider.notifier);

      await notifier.importEntries(
        walkEast('dev', points: 40),
        useIsolate: false,
      );

      final source = container.read(fogProvider).requireValue;
      expect(source.store.diagnostics.totalAreaM2, greaterThan(0));
      expect(await env.log.count(), 40);
    });

    test('clearing the fog keeps the track log', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      await source.store.whenCaughtUp();
      expect(source.store.diagnostics.totalAreaM2, greaterThan(0));

      await container.read(fogProvider.notifier).clearFog();

      expect(source.store.diagnostics.totalAreaM2, 0);
      expect(await env.log.count(), 20);
    });

    test('a cleared fog stays cleared after a restart', () async {
      await env.log.appendAll(walkEast('old'));
      final first = env.createContainer();
      await (await first.read(fogProvider.future)).store.whenCaughtUp();
      await first.read(fogProvider.notifier).clearFog();
      first.dispose();

      final second = env.createContainer();
      addTearDown(second.dispose);
      final restarted = await second.read(fogProvider.future);
      await restarted.store.whenCaughtUp();

      expect(restarted.store.diagnostics.totalAreaM2, 0);
      expect(await env.log.count(), 20);
    });

    test('rebuilding redraws the fog from the track log', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      await source.store.whenCaughtUp();
      final area = source.store.diagnostics.totalAreaM2;
      await container.read(fogProvider.notifier).clearFog();

      await container.read(fogProvider.notifier).rebuild(useIsolate: false);

      expect(source.store.diagnostics.totalAreaM2, closeTo(area, 1e-6));
    });

    test('a failed replay still shows the stored fog', () async {
      final seen = offsetMeters(krakowLat, krakowLng);
      final stored = await FogStore.open(env.tiles);
      await stored.applyPoint(
        sessionId: 'old',
        latitude: seen.lat,
        longitude: seen.lng,
      );
      await stored.flush();
      await stored.dispose();
      env = FogTestEnvironment(log: _FailingTrackLog(), tiles: env.tiles);
      final container = env.createContainer();
      addTearDown(container.dispose);

      final source = await container.read(fogProvider.future);

      await source.store.whenCaughtUp();

      expect(await coverageAt(source.store, seen.lat, seen.lng), 1);
    });
  });
}

class _FailingTrackLog extends InMemoryTrackLogStorage {
  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    throw StateError('damaged track block');
  }
}
