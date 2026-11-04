import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/logic/stats_period.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_records_grid.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_weekly_chart.dart';

class StatsOverviewState {
  const StatsOverviewState({
    required this.range,
    required this.newAreaKm2,
    required this.distanceKm,
    required this.questsCount,
    required this.weeklyBars,
    required this.visitedCountriesCount,
    required this.visitedRegionsCount,
    required this.visitedCitiesCount,
    required this.countryCodes,
    required this.records,
    required this.discoveredCities,
    this.openStreakDays = 0,
    this.maxOpenStreakDays = 0,
    this.recordingStreakDays = 0,
    this.maxRecordingStreakDays = 0,
  });

  final StatsPeriodRange range;
  final double newAreaKm2;
  final double distanceKm;
  final int questsCount;
  final List<WeeklyBarItem> weeklyBars;
  final int visitedCountriesCount;
  final int visitedRegionsCount;
  final int visitedCitiesCount;
  final List<String> countryCodes;
  final List<RecordTileItem> records;

  /// The three most discovered cities.
  final List<DiscoveredRegion> discoveredCities;
  final int openStreakDays;
  final int maxOpenStreakDays;
  final int recordingStreakDays;
  final int maxRecordingStreakDays;

  StatsPeriod get period => range.period;
}

/// Quests completed within the given period.
final completedQuestsInPeriodProvider = Provider.family<int, StatsPeriodRange>((
  ref,
  range,
) {
  final quests = ref.watch(questsProvider).quests;
  final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
  return quests.where((q) {
    final at = q.completedAt?.toLocal();
    return q.isCompleted &&
        at != null &&
        !at.isBefore(range.start) &&
        at.isBefore(end);
  }).length;
});

class StatsPeriodFilterNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.month;

  StatsPeriod get period => state;
  set period(StatsPeriod value) => state = value;
}

final statsPeriodFilterProvider =
    NotifierProvider<StatsPeriodFilterNotifier, StatsPeriod>(
      StatsPeriodFilterNotifier.new,
    );

class StatsDateFilterNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  DateTime get date => state;
  set date(DateTime value) => state = value;
}

final statsDateFilterProvider =
    NotifierProvider<StatsDateFilterNotifier, DateTime>(
      StatsDateFilterNotifier.new,
    );

final statsOverviewProvider =
    AsyncNotifierProvider<StatsOverviewNotifier, StatsOverviewState>(
      StatsOverviewNotifier.new,
    );

class StatsOverviewNotifier extends AsyncNotifier<StatsOverviewState> {
  @override
  Future<StatsOverviewState> build() async {
    final period = ref.watch(statsPeriodFilterProvider);
    final selectedDate = ref.watch(statsDateFilterProvider);
    ref.watch(statisticsRevisionProvider);
    return _loadStatsFor(statsPeriodRange(period, selectedDate));
  }

  Future<void> setPeriod(StatsPeriod period) async {
    ref.read(statsDateFilterProvider.notifier).date = DateTime.now();
    ref.read(statsPeriodFilterProvider.notifier).period = period;
  }

  Future<void> previousPeriod() async => _shift(-1);

  Future<void> nextPeriod() async => _shift(1);

  void _shift(int steps) {
    final period = ref.read(statsPeriodFilterProvider);
    final now = DateTime.now();
    var date = shiftStatsPeriod(
      period,
      ref.read(statsDateFilterProvider),
      steps,
    );
    if (date.isAfter(now)) date = now;
    ref.read(statsDateFilterProvider.notifier).date = date;
  }

  Future<StatsOverviewState> _loadStatsFor(StatsPeriodRange range) async {
    final statsStorage = ref.watch(statisticsStorageProvider);
    final regionStorage = ref.watch(regionStorageProvider);
    final fromDate = _fmtDate(range.start);
    final toDate = _fmtDate(range.end);

    final dailyList = await statsStorage.getDailyStatsRange(
      fromDate: fromDate,
      toDate: toDate,
    );
    final allRegionStats = await statsStorage.getAllRegionStats();

    final totalNewAreaM2 = dailyList.fold<double>(
      0.0,
      (sum, d) => sum + d.newAreaM2,
    );
    final totalDistanceM = dailyList.fold<double>(
      0.0,
      (sum, d) => sum + d.distanceM,
    );
    final questsCount = ref.watch(completedQuestsInPeriodProvider(range));

    final weeklyBars = <WeeklyBarItem>[];
    final thisWeek = statsPeriodRange(StatsPeriod.week, DateTime.now());
    for (var w = 7; w >= 0; w--) {
      final week = statsPeriodRange(
        StatsPeriod.week,
        shiftStatsPeriod(StatsPeriod.week, thisWeek.start, -w),
      );
      final weekList = await statsStorage.getDailyStatsRange(
        fromDate: _fmtDate(week.start),
        toDate: _fmtDate(week.end),
      );
      final weekAreaKm2 =
          weekList.fold<double>(0.0, (sum, d) => sum + d.newAreaM2) / 1000000.0;
      weeklyBars.add(
        WeeklyBarItem(
          isoWeek: isoWeekOf(week.start).week,
          valueKm2: weekAreaKm2,
          isCurrent: w == 0,
        ),
      );
    }

    final longest = await statsStorage.getRecordEntry('longest_route_distance');
    final longestAtMs = longest?.timestampMs;
    final bestDay = await statsStorage.getBestDayStats();
    final hasBestDay = bestDay != null && bestDay.newAreaM2 > 0;

    final records = [
      RecordTileItem(
        type: StatsRecordType.longestRoute,
        value: longest?.value,
        date: longestAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(longestAtMs),
        label: longest?.label,
      ),
      RecordTileItem(
        type: StatsRecordType.bestDay,
        value: hasBestDay ? bestDay.newAreaM2 / 1000000 : null,
        date: hasBestDay ? DateTime.tryParse(bestDay.date) : null,
      ),
    ];

    var visitedCountries = 0;
    var visitedRegions = 0;
    var visitedCities = 0;
    final countryCodes = <String>{};
    final discoveredCities = <DiscoveredRegion>[];

    final activeStats = allRegionStats
        .where((s) => s.discoveredAreaM2 > 0)
        .toList();
    for (final regStat in activeStats) {
      final region = await regionStorage.findRegionById(regStat.regionId);
      if (region == null) continue;
      if (region.type == RegionType.country) {
        visitedCountries++;
        if (region.code != null && region.code!.isNotEmpty) {
          countryCodes.add(region.code!);
        }
      } else if (region.type == RegionType.state) {
        visitedRegions++;
      } else if (region.type == RegionType.city) {
        visitedCities++;
        discoveredCities.add(
          DiscoveredRegion(
            id: region.id,
            type: region.type,
            name: region.displayName,
            areaKm2: regStat.discoveredAreaM2 / 1000000,
            percentage: regStat.discoveryPercentage,
          ),
        );
      }
    }

    discoveredCities.sort((a, b) => b.percentage.compareTo(a.percentage));

    final streakStats = await statsStorage.loadStreakStats();
    const streakService = StreakService();
    final effectiveOpen = streakService.effectiveOpenStreak(streakStats);
    final effectiveRec = streakService.effectiveRecordingStreak(streakStats);

    return StatsOverviewState(
      range: range,
      newAreaKm2: totalNewAreaM2 / 1000000.0,
      distanceKm: totalDistanceM / 1000.0,
      questsCount: questsCount,
      weeklyBars: weeklyBars,
      visitedCountriesCount: visitedCountries,
      visitedRegionsCount: visitedRegions,
      visitedCitiesCount: visitedCities,
      countryCodes: countryCodes.toList(),
      records: records,
      discoveredCities: discoveredCities.take(3).toList(),
      openStreakDays: effectiveOpen,
      maxOpenStreakDays: streakStats.maxOpenStreak,
      recordingStreakDays: effectiveRec,
      maxRecordingStreakDays: streakStats.maxRecordingStreak,
    );
  }

  static String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
