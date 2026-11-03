import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';

abstract interface class StatisticsStorage {
  Future<void> init();
  Future<void> close();

  // Streak operations
  Future<UserStreakStats> loadStreakStats();
  Future<void> saveStreakStats(UserStreakStats stats);

  // Region stats operations
  Future<UserRegionStats?> getRegionStats(int regionId);
  Future<List<UserRegionStats>> getAllRegionStats();
  Future<void> saveRegionStats(Iterable<UserRegionStats> stats);

  // Tile-to-region mapping cache
  Future<int?> getCachedTileRegion({
    required int z,
    required int x,
    required int y,
  });
  Future<void> cacheTileRegion({
    required int z,
    required int x,
    required int y,
    required int regionId,
  });

  // Daily ledger operations
  Future<DailyExplorationStats?> getDailyStats(String date);
  Future<List<DailyExplorationStats>> getDailyStatsRange({
    required String fromDate,
    required String toDate,
  });
  Future<void> saveDailyStats(DailyExplorationStats stats);

  // Personal records
  Future<double?> getRecord(String key);
  Future<void> setRecordIfMax(
    String key,
    double value, {
    String? label,
    int? timestampMs,
  });
}
