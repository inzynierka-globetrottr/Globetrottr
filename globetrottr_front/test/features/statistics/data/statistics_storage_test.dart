import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqfliteStatisticsStorage', () {
    late StatisticsStorage storage;

    setUp(() async {
      storage = SqfliteStatisticsStorage(path: inMemoryDatabasePath);
      await storage.init();
    });

    tearDown(() async {
      await storage.close();
    });

    test('loads empty streak stats initially and persists updates', () async {
      final initial = await storage.loadStreakStats();
      expect(initial.currentOpenStreak, 0);

      const updated = UserStreakStats(
        currentOpenStreak: 3,
        maxOpenStreak: 5,
        lastOpenDate: '2026-11-03',
        currentRecordingStreak: 2,
        maxRecordingStreak: 4,
        lastRecordingDate: '2026-11-03',
      );
      await storage.saveStreakStats(updated);

      final loaded = await storage.loadStreakStats();
      expect(loaded.currentOpenStreak, 3);
      expect(loaded.maxOpenStreak, 5);
      expect(loaded.lastOpenDate, '2026-11-03');
    });

    test('saves and loads region stats', () async {
      const stat1 = UserRegionStats(
        regionId: 100,
        discoveredAreaM2: 50000.0,
        discoveryPercentage: 15.3,
        firstVisitMs: 1600000000,
        lastVisitMs: 1600050000,
        visitsCount: 3,
        timeSpentSeconds: 3600,
      );

      await storage.saveRegionStats([stat1]);

      final loaded = await storage.getRegionStats(100);
      expect(loaded, isNotNull);
      expect(loaded!.discoveredAreaM2, 50000.0);
      expect(loaded.discoveryPercentage, 15.3);
      expect(loaded.visitsCount, 3);
    });

    test('caches and loads tile-to-region associations', () async {
      expect(await storage.getCachedTileRegion(z: 15, x: 100, y: 200), isNull);

      await storage.cacheTileRegion(z: 15, x: 100, y: 200, regionId: 42);

      expect(await storage.getCachedTileRegion(z: 15, x: 100, y: 200), 42);
    });

    test('saves and queries daily stats and ranges', () async {
      const day1 = DailyExplorationStats(
        date: '2026-11-01',
        newAreaM2: 12000.0,
        distanceM: 3500.0,
        durationSeconds: 1800,
      );
      const day2 = DailyExplorationStats(
        date: '2026-11-02',
        newAreaM2: 8000.0,
        distanceM: 2000.0,
        durationSeconds: 1200,
      );

      await storage.saveDailyStats(day1);
      await storage.saveDailyStats(day2);

      final fetched = await storage.getDailyStats('2026-11-01');
      expect(fetched, isNotNull);
      expect(fetched!.distanceM, 3500.0);

      final range = await storage.getDailyStatsRange(
        fromDate: '2026-11-01',
        toDate: '2026-11-02',
      );
      expect(range.length, 2);
    });

    test(
      'updates personal record only when new value exceeds current max',
      () async {
        await storage.setRecordIfMax(
          'max_altitude',
          1500.0,
          label: 'Mount Test',
        );
        expect(await storage.getRecord('max_altitude'), 1500.0);

        // Lower value should not overwrite
        await storage.setRecordIfMax(
          'max_altitude',
          1200.0,
          label: 'Small Hill',
        );
        expect(await storage.getRecord('max_altitude'), 1500.0);

        // Higher value should overwrite
        await storage.setRecordIfMax(
          'max_altitude',
          1987.0,
          label: 'Kasprowy Wierch',
        );
        expect(await storage.getRecord('max_altitude'), 1987.0);
      },
    );
  });
}
