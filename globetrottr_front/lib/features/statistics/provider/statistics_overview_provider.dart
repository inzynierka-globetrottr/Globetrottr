import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_activity_section.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_most_visited_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_period_tabs.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_records_grid.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_weekly_chart.dart';

class StatsOverviewState {
  const StatsOverviewState({
    required this.period,
    required this.selectedDate,
    required this.periodLabel,
    required this.newAreaKm2,
    required this.distanceKm,
    required this.newStreetsCount,
    required this.questsCount,
    required this.weeklyBars,
    required this.visitedCountriesCount,
    required this.visitedRegionsCount,
    required this.visitedCitiesCount,
    required this.countryCodes,
    required this.activities,
    required this.records,
    required this.discoveredCities,
    required this.mostVisitedPlaces,
  });

  final StatsPeriod period;
  final DateTime selectedDate;
  final String periodLabel;
  final double newAreaKm2;
  final double distanceKm;
  final int newStreetsCount;
  final int questsCount;
  final List<WeeklyBarItem> weeklyBars;
  final int visitedCountriesCount;
  final int visitedRegionsCount;
  final int visitedCitiesCount;
  final List<String> countryCodes;
  final List<ActivityDistanceItem> activities;
  final List<RecordTileItem> records;
  final List<DiscoveryRowItem> discoveredCities;
  final List<MostVisitedItem> mostVisitedPlaces;

  StatsOverviewState copyWith({
    StatsPeriod? period,
    DateTime? selectedDate,
    String? periodLabel,
    double? newAreaKm2,
    double? distanceKm,
    int? newStreetsCount,
    int? questsCount,
    List<WeeklyBarItem>? weeklyBars,
    int? visitedCountriesCount,
    int? visitedRegionsCount,
    int? visitedCitiesCount,
    List<String>? countryCodes,
    List<ActivityDistanceItem>? activities,
    List<RecordTileItem>? records,
    List<DiscoveryRowItem>? discoveredCities,
    List<MostVisitedItem>? mostVisitedPlaces,
  }) {
    return StatsOverviewState(
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
      periodLabel: periodLabel ?? this.periodLabel,
      newAreaKm2: newAreaKm2 ?? this.newAreaKm2,
      distanceKm: distanceKm ?? this.distanceKm,
      newStreetsCount: newStreetsCount ?? this.newStreetsCount,
      questsCount: questsCount ?? this.questsCount,
      weeklyBars: weeklyBars ?? this.weeklyBars,
      visitedCountriesCount:
          visitedCountriesCount ?? this.visitedCountriesCount,
      visitedRegionsCount: visitedRegionsCount ?? this.visitedRegionsCount,
      visitedCitiesCount: visitedCitiesCount ?? this.visitedCitiesCount,
      countryCodes: countryCodes ?? this.countryCodes,
      activities: activities ?? this.activities,
      records: records ?? this.records,
      discoveredCities: discoveredCities ?? this.discoveredCities,
      mostVisitedPlaces: mostVisitedPlaces ?? this.mostVisitedPlaces,
    );
  }
}

final completedQuestsCountProvider = Provider<int>((ref) {
  try {
    final quests = ref.watch(questsProvider).quests;
    return quests.where((q) => q.isCompleted).length;
  } catch (_) {
    return 0;
  }
});

final statsOverviewProvider =
    AsyncNotifierProvider<StatsOverviewNotifier, StatsOverviewState>(
      StatsOverviewNotifier.new,
    );

class StatsOverviewNotifier extends AsyncNotifier<StatsOverviewState> {
  StatsPeriod _period = StatsPeriod.month;
  DateTime _selectedDate = DateTime.now();

  @override
  Future<StatsOverviewState> build() async {
    return _loadStatsFor(_period, _selectedDate);
  }

  Future<void> setPeriod(StatsPeriod period) async {
    _period = period;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadStatsFor(_period, _selectedDate));
  }

  Future<void> previousPeriod() async {
    switch (_period) {
      case StatsPeriod.week:
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      case StatsPeriod.month:
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      case StatsPeriod.year:
        _selectedDate = DateTime(_selectedDate.year - 1);
      case StatsPeriod.allTime:
        break;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadStatsFor(_period, _selectedDate));
  }

  Future<void> nextPeriod() async {
    final now = DateTime.now();
    DateTime nextDate;
    switch (_period) {
      case StatsPeriod.week:
        nextDate = _selectedDate.add(const Duration(days: 7));
      case StatsPeriod.month:
        nextDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      case StatsPeriod.year:
        nextDate = DateTime(_selectedDate.year + 1);
      case StatsPeriod.allTime:
        return;
    }
    if (nextDate.isAfter(now)) {
      _selectedDate = now;
    } else {
      _selectedDate = nextDate;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadStatsFor(_period, _selectedDate));
  }

  Future<StatsOverviewState> _loadStatsFor(
    StatsPeriod period,
    DateTime date,
  ) async {
    ref.watch(statisticsRevisionProvider);
    final statsStorage = ref.watch(statisticsStorageProvider);
    final regionStorage = ref.watch(regionStorageProvider);
    final currentLocale = ref.watch(localeProvider);
    final isPolish =
        (currentLocale?.languageCode ??
            WidgetsBinding.instance.platformDispatcher.locale.languageCode) ==
        'pl';

    final String fromDate;
    final String toDate;
    final String periodLabel;

    switch (period) {
      case StatsPeriod.week:
        final mon = date.subtract(Duration(days: date.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        fromDate = _fmtDate(mon);
        toDate = _fmtDate(sun);
        periodLabel = isPolish
            ? 'Tydzień ${_isoWeekNumber(mon)} · ${mon.year}'
            : 'Week ${_isoWeekNumber(mon)} · ${mon.year}';
      case StatsPeriod.month:
        final firstDay = DateTime(date.year, date.month);
        final lastDay = DateTime(date.year, date.month + 1, 0);
        fromDate = _fmtDate(firstDay);
        toDate = _fmtDate(lastDay);
        final monthName = (isPolish
            ? _monthNamesPl
            : _monthNamesEn)[date.month - 1];
        periodLabel = '$monthName ${date.year}';
      case StatsPeriod.year:
        fromDate = '${date.year}-01-01';
        toDate = '${date.year}-12-31';
        periodLabel = '${date.year}';
      case StatsPeriod.allTime:
        fromDate = '1970-01-01';
        toDate = '2099-12-31';
        periodLabel = isPolish ? 'Wszystko' : 'All-Time';
    }

    var dailyList = await statsStorage.getDailyStatsRange(
      fromDate: fromDate,
      toDate: toDate,
    );
    var allRegionStats = await statsStorage.getAllRegionStats();

    final hasAreaStats =
        dailyList.any((d) => d.newAreaM2 > 0) ||
        allRegionStats.any((r) => r.discoveredAreaM2 > 0);
    if (!hasAreaStats) {
      final fogStorage = ref.read(fogTileStorageProvider);
      final baseTiles = await fogStorage.loadBaseTilesWithArea();
      if (baseTiles.isNotEmpty) {
        await ref.read(fogProvider.notifier).backfillStatsIfEmpty();
        dailyList = await statsStorage.getDailyStatsRange(
          fromDate: fromDate,
          toDate: toDate,
        );
        allRegionStats = await statsStorage.getAllRegionStats();
      }
    }

    final totalNewAreaM2 = dailyList.fold<double>(
      0.0,
      (sum, d) => sum + d.newAreaM2,
    );
    final totalDistanceM = dailyList.fold<double>(
      0.0,
      (sum, d) => sum + d.distanceM,
    );
    final totalStreets = dailyList.fold<int>(
      0,
      (sum, d) => sum + d.newStreetsCount,
    );

    final questsCount = ref.watch(completedQuestsCountProvider);

    final walkKm =
        dailyList.fold<double>(0.0, (sum, d) => sum + d.walkDistanceM) / 1000.0;
    final bikeKm =
        dailyList.fold<double>(0.0, (sum, d) => sum + d.bikeDistanceM) / 1000.0;
    final runKm =
        dailyList.fold<double>(0.0, (sum, d) => sum + d.runDistanceM) / 1000.0;
    final otherKm =
        dailyList.fold<double>(0.0, (sum, d) => sum + d.otherDistanceM) /
        1000.0;
    final maxActivity = [walkKm, bikeKm, runKm, otherKm].reduce(math.max);

    final activities = [
      ActivityDistanceItem(
        label: isPolish ? 'Pieszo' : 'Walk',
        distanceKm: walkKm,
        percentage: maxActivity > 0
            ? (walkKm / maxActivity).clamp(0.0, 1.0)
            : 0.0,
        type: StatsActivityType.walk,
      ),
      ActivityDistanceItem(
        label: isPolish ? 'Rower' : 'Bike',
        distanceKm: bikeKm,
        percentage: maxActivity > 0
            ? (bikeKm / maxActivity).clamp(0.0, 1.0)
            : 0.0,
        type: StatsActivityType.bike,
      ),
      ActivityDistanceItem(
        label: isPolish ? 'Bieg' : 'Run',
        distanceKm: runKm,
        percentage: maxActivity > 0
            ? (runKm / maxActivity).clamp(0.0, 1.0)
            : 0.0,
        type: StatsActivityType.run,
      ),
      ActivityDistanceItem(
        label: isPolish ? 'Inne' : 'Other',
        distanceKm: otherKm,
        percentage: maxActivity > 0
            ? (otherKm / maxActivity).clamp(0.0, 1.0)
            : 0.0,
        type: StatsActivityType.other,
      ),
    ];

    final weeklyBars = <WeeklyBarItem>[];
    final now = DateTime.now();
    final currentMon = now.subtract(Duration(days: now.weekday - 1));
    for (var w = 7; w >= 0; w--) {
      final target = currentMon.subtract(Duration(days: 7 * w));
      final sun = target.add(const Duration(days: 6));
      final weekList = await statsStorage.getDailyStatsRange(
        fromDate: _fmtDate(target),
        toDate: _fmtDate(sun),
      );
      final weekAreaKm2 =
          weekList.fold<double>(0.0, (sum, d) => sum + d.newAreaM2) / 1000000.0;
      final isCur = w == 0;
      final label = isCur
          ? (isPolish ? 'teraz' : 'now')
          : '${_isoWeekNumber(target)}';
      weeklyBars.add(
        WeeklyBarItem(label: label, valueKm2: weekAreaKm2, isCurrent: isCur),
      );
    }

    final highest = await statsStorage.getRecordEntry('max_altitude');
    final furthest = await statsStorage.getRecordEntry('furthest_distance');
    final longest = await statsStorage.getRecordEntry('longest_route_distance');
    final bestDay = await statsStorage.getBestDayStats();

    final records = [
      RecordTileItem(
        header: isPolish ? 'NAJWYŻEJ' : 'HIGHEST',
        value: highest != null ? '${highest.value.round()} m' : '–',
        subtitle: highest?.label ?? '–',
        type: StatsRecordType.highest,
      ),
      RecordTileItem(
        header: isPolish ? 'NAJDALEJ' : 'FURTHEST',
        value: furthest != null
            ? '${(furthest.value / 1000).toStringAsFixed(1)} km'
            : '–',
        subtitle: furthest?.label ?? '–',
        type: StatsRecordType.furthest,
      ),
      RecordTileItem(
        header: isPolish ? 'NAJDŁUŻSZA TRASA' : 'LONGEST ROUTE',
        value: longest != null
            ? '${(longest.value / 1000).toStringAsFixed(1)} km'
            : '–',
        subtitle: longest?.label ?? '–',
        type: StatsRecordType.longestRoute,
      ),
      RecordTileItem(
        header: isPolish ? 'NAJLEPSZY DZIEŃ' : 'BEST DAY',
        value: (bestDay != null && bestDay.newAreaM2 > 0)
            ? '+${(bestDay.newAreaM2 / 1000000).toStringAsFixed(2)} km²'
            : '–',
        subtitle: (bestDay != null && bestDay.newAreaM2 > 0)
            ? _formatShortDate(bestDay.date, isPolish)
            : '–',
        type: StatsRecordType.bestDay,
      ),
    ];

    var visitedCountries = 0;
    var visitedRegions = 0;
    var visitedCities = 0;
    final countryCodes = <String>{};
    final discoveredCities = <DiscoveryRowItem>[];

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
          DiscoveryRowItem(
            id: region.id,
            name: region.name,
            percentage: regStat.discoveryPercentage,
          ),
        );
      }
    }

    discoveredCities.sort((a, b) => b.percentage.compareTo(a.percentage));

    final mostVisitedList =
        allRegionStats.where((s) => s.visitsCount > 0).toList()
          ..sort((a, b) => b.visitsCount.compareTo(a.visitsCount));

    final mostVisitedPlaces = <MostVisitedItem>[];
    for (final s in mostVisitedList.take(5)) {
      final region = await regionStorage.findRegionById(s.regionId);
      if (region != null) {
        mostVisitedPlaces.add(
          MostVisitedItem(name: region.name, count: s.visitsCount),
        );
      }
    }

    return StatsOverviewState(
      period: period,
      selectedDate: date,
      periodLabel: periodLabel,
      newAreaKm2: totalNewAreaM2 / 1000000.0,
      distanceKm: totalDistanceM / 1000.0,
      newStreetsCount: totalStreets,
      questsCount: questsCount,
      weeklyBars: weeklyBars,
      visitedCountriesCount: visitedCountries,
      visitedRegionsCount: visitedRegions,
      visitedCitiesCount: visitedCities,
      countryCodes: countryCodes.toList(),
      activities: activities,
      records: records,
      discoveredCities: discoveredCities,
      mostVisitedPlaces: mostVisitedPlaces,
    );
  }

  static String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    return 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
  }

  static String _formatShortDate(String yyyyMmDd, bool isPolish) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    final day = int.tryParse(parts[2]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final shortMonths = isPolish ? _shortMonthsPl : _shortMonthsEn;
    final mStr = (month >= 1 && month <= 12) ? shortMonths[month - 1] : '';
    return isPolish ? '$day $mStr' : '$mStr $day';
  }

  static const _shortMonthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _shortMonthsPl = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];

  static const _monthNamesEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _monthNamesPl = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];
}
