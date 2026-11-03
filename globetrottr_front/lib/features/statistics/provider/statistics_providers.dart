import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';

final regionStorageProvider = Provider<RegionStorage>((ref) {
  final storage = SqfliteRegionStorage();
  ref.onDispose(storage.close);
  return storage;
});

final statisticsStorageProvider = Provider<StatisticsStorage>((ref) {
  final storage = SqfliteStatisticsStorage();
  ref.onDispose(storage.close);
  return storage;
});

final statisticsTrackerProvider = Provider<StatisticsTracker>((ref) {
  return StatisticsTracker(
    regionStorage: ref.watch(regionStorageProvider),
    statisticsStorage: ref.watch(statisticsStorageProvider),
  );
});

final streakStatsProvider =
    AsyncNotifierProvider<StreakStatsNotifier, UserStreakStats>(
      StreakStatsNotifier.new,
    );

class StreakStatsNotifier extends AsyncNotifier<UserStreakStats> {
  @override
  Future<UserStreakStats> build() async {
    final storage = ref.watch(statisticsStorageProvider);
    return storage.loadStreakStats();
  }

  Future<void> recordAppOpen() async {
    final tracker = ref.read(statisticsTrackerProvider);
    final storage = ref.read(statisticsStorageProvider);
    final current = state.value ?? await storage.loadStreakStats();
    final updated = tracker.streakService.recordAppOpen(current);
    await storage.saveStreakStats(updated);
    state = AsyncData(updated);
  }
}

final userRegionStatsProvider = FutureProvider<List<UserRegionStats>>((
  ref,
) async {
  final storage = ref.watch(statisticsStorageProvider);
  return storage.getAllRegionStats();
});

final todayExplorationStatsProvider = FutureProvider<DailyExplorationStats?>((
  ref,
) async {
  final storage = ref.watch(statisticsStorageProvider);
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return storage.getDailyStats('$y-$m-$d');
});
