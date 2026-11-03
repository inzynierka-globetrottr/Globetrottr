import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('StatisticsTracker', () {
    late Directory tempDir;
    late RegionStorage regionStorage;
    late StatisticsStorage statsStorage;
    late StatisticsTracker tracker;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stats_tracker_test_');
      regionStorage = SqfliteRegionStorage(path: '${tempDir.path}/regions.db');
      await regionStorage.init();

      statsStorage = SqfliteStatisticsStorage(path: '${tempDir.path}/stats.db');
      await statsStorage.init();

      tracker = StatisticsTracker(
        regionStorage: regionStorage,
        statisticsStorage: statsStorage,
      );

      // Seed Poland -> Małopolska -> Kraków
      await regionStorage.insertRegions([
        const Region(
          id: 1,
          parentId: null,
          name: 'Polska',
          type: RegionType.country,
          code: 'PL',
          totalAreaKm2: 312696.0,
          minLat: 49.0,
          maxLat: 55.0,
          minLon: 14.0,
          maxLon: 24.5,
        ),
        const Region(
          id: 10,
          parentId: 1,
          name: 'Małopolskie',
          type: RegionType.state,
          code: null,
          totalAreaKm2: 15183.0,
          minLat: 49.1,
          maxLat: 50.5,
          minLon: 19.0,
          maxLon: 21.4,
        ),
        const Region(
          id: 100,
          parentId: 10,
          name: 'Kraków',
          type: RegionType.city,
          code: null,
          totalAreaKm2: 326.8,
          minLat: 49.95,
          maxLat: 50.15,
          minLon: 19.80,
          maxLon: 20.20,
        ),
      ]);
    });

    tearDown(() async {
      await regionStorage.close();
      await statsStorage.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'onTilesCommitted attributes area to city and parent hierarchy',
      () async {
        // Kraków center is around lat 50.06, lon 19.94
        // Web Mercator tile at z=15 for Kraków center:
        // x = ((19.94 + 180) / 360 * 32768).floor() = 18199
        // lat 50.06 -> y ≈ 11116
        const tileId = FogTileId(15, 18199, 11116);

        final now = DateTime(2026, 11, 3, 12);
        await tracker.onTilesCommitted(
          const [TileAreaDelta(id: tileId, areaDeltaM2: 50000.0)],
          now: now,
        );

        // Verify City stats (Kraków)
        final cityStats = await statsStorage.getRegionStats(100);
        expect(cityStats, isNotNull);
        expect(cityStats!.discoveredAreaM2, 50000.0);
        // 50,000 m2 = 0.05 km2 / 326.8 km2 * 100 ≈ 0.0153%
        expect(cityStats.discoveryPercentage, closeTo(0.0153, 0.001));

        // Verify State stats (Małopolskie)
        final stateStats = await statsStorage.getRegionStats(10);
        expect(stateStats, isNotNull);
        expect(stateStats!.discoveredAreaM2, 50000.0);

        // Verify Country stats (Polska)
        final countryStats = await statsStorage.getRegionStats(1);
        expect(countryStats, isNotNull);
        expect(countryStats!.discoveredAreaM2, 50000.0);

        // Verify Daily ledger
        final daily = await statsStorage.getDailyStats('2026-11-03');
        expect(daily, isNotNull);
        expect(daily!.newAreaM2, 50000.0);
      },
    );

    test(
      'recordTripSession updates daily distance and recording streak',
      () async {
        final now = DateTime(2026, 11, 3, 14);

        await tracker.recordTripSession(
          distanceM: 3500.0,
          durationSeconds: 1800,
          activityType: 'walk',
          maxAltitudeM: 250.0,
          now: now,
        );

        final daily = await statsStorage.getDailyStats('2026-11-03');
        expect(daily, isNotNull);
        expect(daily!.distanceM, 3500.0);
        expect(daily.walkDistanceM, 3500.0);
        expect(daily.durationSeconds, 1800);

        final streak = await statsStorage.loadStreakStats();
        expect(streak.currentRecordingStreak, 1);
        expect(streak.lastRecordingDate, '2026-11-03');

        final maxAlt = await statsStorage.getRecord('max_altitude');
        expect(maxAlt, 250.0);
      },
    );

    test(
      'rebuildFromFogTiles recalculates stats from an entire set of fog tiles',
      () async {
        const tile1 = FogTileId(15, 18199, 11116); // Kraków
        const tile2 = FogTileId(15, 18200, 11116); // Kraków adjacent tile

        const tiles = [
          TileAreaDelta(id: tile1, areaDeltaM2: 40000.0),
          TileAreaDelta(id: tile2, areaDeltaM2: 60000.0),
        ];

        await tracker.rebuildFromFogTiles(tiles);

        final cityStats = await statsStorage.getRegionStats(100);
        expect(cityStats, isNotNull);
        expect(cityStats!.discoveredAreaM2, 100000.0);
        // 100,000 m2 = 0.1 km2 / 326.8 km2 * 100 ≈ 0.0306%
        expect(cityStats.discoveryPercentage, closeTo(0.0306, 0.001));

        final stateStats = await statsStorage.getRegionStats(10);
        expect(stateStats, isNotNull);
        expect(stateStats!.discoveredAreaM2, 100000.0);
      },
    );
  });
}
