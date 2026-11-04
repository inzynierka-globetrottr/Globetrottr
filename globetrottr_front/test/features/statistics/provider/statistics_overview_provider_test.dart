import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_overview_provider.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

class _EmptyStatistics extends Fake implements StatisticsStorage {
  @override
  Future<List<DailyExplorationStats>> getDailyStatsRange({
    required String fromDate,
    required String toDate,
  }) async => [];

  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => [];

  @override
  Future<UserRecordEntry?> getRecordEntry(String key) async => null;

  @override
  Future<DailyExplorationStats?> getBestDayStats() async => null;

  @override
  Future<UserStreakStats> loadStreakStats() async => UserStreakStats.empty;
}

class _NoRegions extends Fake implements RegionStorage {
  @override
  Future<Region?> findRegionById(int id) async => null;
}

void main() {
  test('overview loads empty stats without touching the fog', () async {
    final container = ProviderContainer(
      overrides: [
        statisticsStorageProvider.overrideWithValue(_EmptyStatistics()),
        regionStorageProvider.overrideWithValue(_NoRegions()),
        completedQuestsCountProvider.overrideWithValue(0),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(statsOverviewProvider.future);

    expect(state.newAreaKm2, 0);
    expect(state.visitedCountriesCount, 0);
  });
}
