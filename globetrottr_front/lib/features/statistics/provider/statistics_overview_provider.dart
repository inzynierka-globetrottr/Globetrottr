import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
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

  final StatsPeriod period;
  final DateTime selectedDate;
  final String periodLabel;
  final double newAreaKm2;
  final double distanceKm;
  final int questsCount;
  final List<WeeklyBarItem> weeklyBars;
  final int visitedCountriesCount;
  final int visitedRegionsCount;
  final int visitedCitiesCount;
  final List<String> countryCodes;
  final List<RecordTileItem> records;
  final List<DiscoveryRowItem> discoveredCities;
  final int openStreakDays;
  final int maxOpenStreakDays;
  final int recordingStreakDays;
  final int maxRecordingStreakDays;

  StatsOverviewState copyWith({
    StatsPeriod? period,
    DateTime? selectedDate,
    String? periodLabel,
    double? newAreaKm2,
    double? distanceKm,
    int? questsCount,
    List<WeeklyBarItem>? weeklyBars,
    int? visitedCountriesCount,
    int? visitedRegionsCount,
    int? visitedCitiesCount,
    List<String>? countryCodes,
    List<RecordTileItem>? records,
    List<DiscoveryRowItem>? discoveredCities,
    int? openStreakDays,
    int? maxOpenStreakDays,
    int? recordingStreakDays,
    int? maxRecordingStreakDays,
  }) {
    return StatsOverviewState(
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
      periodLabel: periodLabel ?? this.periodLabel,
      newAreaKm2: newAreaKm2 ?? this.newAreaKm2,
      distanceKm: distanceKm ?? this.distanceKm,
      questsCount: questsCount ?? this.questsCount,
      weeklyBars: weeklyBars ?? this.weeklyBars,
      visitedCountriesCount:
          visitedCountriesCount ?? this.visitedCountriesCount,
      visitedRegionsCount: visitedRegionsCount ?? this.visitedRegionsCount,
      visitedCitiesCount: visitedCitiesCount ?? this.visitedCitiesCount,
      countryCodes: countryCodes ?? this.countryCodes,
      records: records ?? this.records,
      discoveredCities: discoveredCities ?? this.discoveredCities,
      openStreakDays: openStreakDays ?? this.openStreakDays,
      maxOpenStreakDays: maxOpenStreakDays ?? this.maxOpenStreakDays,
      recordingStreakDays: recordingStreakDays ?? this.recordingStreakDays,
      maxRecordingStreakDays:
          maxRecordingStreakDays ?? this.maxRecordingStreakDays,
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
    return _loadStatsFor(period, selectedDate);
  }

  Future<void> setPeriod(StatsPeriod period) async {
    ref.read(statsDateFilterProvider.notifier).date = DateTime.now();
    ref.read(statsPeriodFilterProvider.notifier).period = period;
  }

  Future<void> previousPeriod() async {
    final period = ref.read(statsPeriodFilterProvider);
    final selectedDate = ref.read(statsDateFilterProvider);
    DateTime nextDate = selectedDate;
    switch (period) {
      case StatsPeriod.week:
        nextDate = selectedDate.subtract(const Duration(days: 7));
      case StatsPeriod.month:
        nextDate = DateTime(selectedDate.year, selectedDate.month - 1);
      case StatsPeriod.year:
        nextDate = DateTime(selectedDate.year - 1);
      case StatsPeriod.allTime:
        break;
    }
    ref.read(statsDateFilterProvider.notifier).date = nextDate;
  }

  Future<void> nextPeriod() async {
    final period = ref.read(statsPeriodFilterProvider);
    final selectedDate = ref.read(statsDateFilterProvider);
    final now = DateTime.now();
    DateTime nextDate = selectedDate;
    switch (period) {
      case StatsPeriod.week:
        nextDate = selectedDate.add(const Duration(days: 7));
      case StatsPeriod.month:
        nextDate = DateTime(selectedDate.year, selectedDate.month + 1);
      case StatsPeriod.year:
        nextDate = DateTime(selectedDate.year + 1);
      case StatsPeriod.allTime:
        return;
    }
    if (nextDate.isAfter(now)) {
      nextDate = now;
    }
    ref.read(statsDateFilterProvider.notifier).date = nextDate;
  }

  Future<StatsOverviewState> _loadStatsFor(
    StatsPeriod period,
    DateTime date,
  ) async {
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
    final questsCount = ref.watch(completedQuestsCountProvider);

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

    final longest = await statsStorage.getRecordEntry('longest_route_distance');
    final bestDay = await statsStorage.getBestDayStats();

    final records = [
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

    final streakStats = await statsStorage.loadStreakStats();
    const streakService = StreakService();
    final effectiveOpen = streakService.effectiveOpenStreak(streakStats);
    final effectiveRec = streakService.effectiveRecordingStreak(streakStats);

    return StatsOverviewState(
      period: period,
      selectedDate: date,
      periodLabel: periodLabel,
      newAreaKm2: totalNewAreaM2 / 1000000.0,
      distanceKm: totalDistanceM / 1000.0,
      questsCount: questsCount,
      weeklyBars: weeklyBars,
      visitedCountriesCount: visitedCountries,
      visitedRegionsCount: visitedRegions,
      visitedCitiesCount: visitedCities,
      countryCodes: countryCodes.toList(),
      records: records,
      discoveredCities: discoveredCities,
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

  static int _isoWeekNumber(DateTime date) {
    final dUtc = DateTime.utc(date.year, date.month, date.day);
    final thursday = dUtc.add(Duration(days: 4 - dUtc.weekday));
    final firstDayOfYear = DateTime.utc(thursday.year);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear - 1) ~/ 7) + 1;
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
