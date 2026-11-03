import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final statsStorage = ref.watch(statisticsStorageProvider);
    final regionStorage = ref.watch(regionStorageProvider);

    final allRegionStats = await statsStorage.getAllRegionStats();

    var visitedCountries = 0;
    var visitedRegions = 0;
    var visitedCities = 0;
    final countryCodes = <String>{};
    final discoveredCities = <DiscoveryRowItem>[];

    for (final regStat in allRegionStats) {
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
            name: region.name,
            percentage: regStat.discoveryPercentage,
          ),
        );
      }
    }

    // TODO(data): Provide mock/fallback values matching design when real entries are empty
    final finalCountriesCount = visitedCountries > 0 ? visitedCountries : 3;
    final finalRegionsCount = visitedRegions > 0 ? visitedRegions : 8;
    final finalCitiesCount = visitedCities > 0 ? visitedCities : 12;
    final finalCountryCodes = countryCodes.isNotEmpty
        ? countryCodes.toList()
        : ['PL', 'CZ', 'SK'];

    final finalDiscoveredCities = discoveredCities.isNotEmpty
        ? discoveredCities
        : const [
            DiscoveryRowItem(name: 'Kraków', percentage: 7.3),
            DiscoveryRowItem(name: 'Zabierzów', percentage: 1.1),
            DiscoveryRowItem(name: 'Skawina', percentage: 1.0),
          ];

    final monthNames = [
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
    final periodLabel = '${monthNames[date.month - 1]} ${date.year}';

    // TODO(data): Read real ledger data from StatisticsStorage for period aggregations
    return StatsOverviewState(
      period: period,
      selectedDate: date,
      periodLabel: periodLabel,
      newAreaKm2: 1.84,
      distanceKm: 46.2,
      newStreetsCount: 128,
      questsCount: 5,
      weeklyBars: const [
        WeeklyBarItem(label: '37', valueKm2: 0.12),
        WeeklyBarItem(label: '38', valueKm2: 0.30),
        WeeklyBarItem(label: '39', valueKm2: 0.22),
        WeeklyBarItem(label: '40', valueKm2: 0.45),
        WeeklyBarItem(label: '41', valueKm2: 0.18),
        WeeklyBarItem(label: '42', valueKm2: 0.52),
        WeeklyBarItem(label: '43', valueKm2: 0.38),
        WeeklyBarItem(label: 'teraz', valueKm2: 0.61, isCurrent: true),
      ],
      visitedCountriesCount: finalCountriesCount,
      visitedRegionsCount: finalRegionsCount,
      visitedCitiesCount: finalCitiesCount,
      countryCodes: finalCountryCodes,
      activities: const [
        ActivityDistanceItem(label: 'Pieszo', distanceKm: 198, percentage: 1.0),
        ActivityDistanceItem(label: 'Rower', distanceKm: 102, percentage: 0.52),
        ActivityDistanceItem(label: 'Bieg', distanceKm: 14, percentage: 0.08),
        ActivityDistanceItem(label: 'Inne', distanceKm: 4, percentage: 0.03),
      ],
      records: const [
        RecordTileItem(
          header: 'NAJWYŻEJ',
          value: '1 987 m',
          subtitle: 'Kasprowy Wierch',
        ),
        RecordTileItem(header: 'NAJDALEJ', value: '412 km', subtitle: 'Gdańsk'),
        RecordTileItem(
          header: 'NAJDŁUŻSZA TRASA',
          value: '22,6 km',
          subtitle: 'Rower · Tyniec',
        ),
        RecordTileItem(
          header: 'NAJLEPSZY DZIEŃ',
          value: '+0,74 km²',
          subtitle: '12 paź',
        ),
      ],
      discoveredCities: finalDiscoveredCities,
      mostVisitedPlaces: const [
        MostVisitedItem(name: 'Bulwary Wiślane', count: 105),
        MostVisitedItem(name: 'Rynek Główny', count: 41),
        MostVisitedItem(name: 'Kopiec Krakusa', count: 30),
      ],
    );
  }
}
