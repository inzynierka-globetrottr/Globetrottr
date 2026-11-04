import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/quests_notifier.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_state.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
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

Quest _completed(int id, DateTime at) => Quest(
  id: id,
  title: 'q$id',
  type: 'VISIT_POINTS',
  rewardPoints: 10,
  progress: 1,
  isStarted: true,
  isCompleted: true,
  completedAt: at,
);

class _Quests extends QuestsNotifier {
  @override
  QuestsState build() => QuestsState(
    quests: [
      _completed(1, DateTime(2026, 10, 2)),
      _completed(2, DateTime(2026, 10, 30, 22)),
      _completed(3, DateTime(2026, 9, 30, 23)),
    ],
    hasLoaded: true,
  );
}

class _FixedDate extends StatsDateFilterNotifier {
  @override
  DateTime build() => DateTime(2026, 10, 15);
}

class _FiveCities extends Fake implements RegionStorage {
  @override
  Future<Region?> findRegionById(int id) async => Region(
    id: id,
    parentId: null,
    name: 'city$id',
    type: RegionType.city,
    code: null,
    totalAreaKm2: 10,
    minLat: 0,
    maxLat: 1,
    minLon: 0,
    maxLon: 1,
  );
}

class _FiveCityStats extends _EmptyStatistics {
  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => [
    for (var i = 1; i <= 5; i++)
      UserRegionStats(
        regionId: i,
        discoveredAreaM2: i * 1000.0,
        discoveryPercentage: i.toDouble(),
      ),
  ];
}

void main() {
  test('overview loads empty stats without touching the fog', () async {
    final container = ProviderContainer(
      overrides: [
        statisticsStorageProvider.overrideWithValue(_EmptyStatistics()),
        regionStorageProvider.overrideWithValue(_NoRegions()),
        completedQuestsInPeriodProvider.overrideWith((ref, range) => 0),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(statsOverviewProvider.future);

    expect(state.newAreaKm2, 0);
    expect(state.visitedCountriesCount, 0);
  });

  test('the overview shows the three most discovered cities', () async {
    final container = ProviderContainer(
      overrides: [
        statisticsStorageProvider.overrideWithValue(_FiveCityStats()),
        regionStorageProvider.overrideWithValue(_FiveCities()),
        questsProvider.overrideWith(_Quests.new),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(statsOverviewProvider.future);

    expect(state.discoveredCities.map((c) => c.id), [5, 4, 3]);
    expect(state.visitedCitiesCount, 5);
  });

  test('quests count those completed in the selected period', () async {
    final container = ProviderContainer(
      overrides: [
        statisticsStorageProvider.overrideWithValue(_EmptyStatistics()),
        regionStorageProvider.overrideWithValue(_NoRegions()),
        questsProvider.overrideWith(_Quests.new),
        statsDateFilterProvider.overrideWith(_FixedDate.new),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(statsOverviewProvider.future);

    expect(state.questsCount, 2);
  });
}
