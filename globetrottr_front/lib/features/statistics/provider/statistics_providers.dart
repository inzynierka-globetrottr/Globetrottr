import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/regions/data/region_pack_service.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';

final regionStorageProvider = Provider<RegionStorage>((ref) {
  final storage = SqfliteRegionStorage();
  ref.onDispose(storage.close);
  return storage;
});

final regionPackServiceProvider = Provider<RegionPackService>((ref) {
  return RegionPackService(storage: ref.watch(regionStorageProvider));
});

final statisticsStorageProvider = Provider<StatisticsStorage>((ref) {
  final storage = SqfliteStatisticsStorage();
  ref.onDispose(storage.close);
  return storage;
});

final statisticsRevisionProvider =
    NotifierProvider<StatisticsRevisionNotifier, int>(
      StatisticsRevisionNotifier.new,
    );

class StatisticsRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Countries whose cities the tracker needs; `FogNotifier` installs their
/// files and rebuilds the statistics.
final missingRegionPacksProvider = Provider<StreamController<String>>((ref) {
  final controller = StreamController<String>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

final statisticsTrackerProvider = Provider<StatisticsTracker>((ref) {
  final missingPacks = ref.watch(missingRegionPacksProvider);
  return StatisticsTracker(
    regionStorage: ref.watch(regionStorageProvider),
    statisticsStorage: ref.watch(statisticsStorageProvider),
    onUpdated: () => ref.read(statisticsRevisionProvider.notifier).bump(),
    onMissingPack: (code) {
      if (!missingPacks.isClosed) missingPacks.add(code);
    },
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

  Future<void> recordAppOpen({DateTime? now}) async {
    final storage = ref.read(statisticsStorageProvider);
    final current = await storage.loadStreakStats();
    final updated = const StreakService().recordAppOpen(
      current,
      now: now ?? ref.read(clockProvider)(),
    );
    if (updated.lastOpenDate == current.lastOpenDate) return;
    await storage.saveStreakStats(updated);
    state = AsyncData(updated);
    ref.read(statisticsRevisionProvider.notifier).bump();
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
