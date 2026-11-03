import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_overview_provider.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/city_detail_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/countries_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/region_detail_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_accordion_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_activity_section.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_countries_banner.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_date_navigator.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_detail_progress_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metadata_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metric_tile.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metrics_row.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_most_visited_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_period_tabs.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_streaks_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_records_grid.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_weekly_chart.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

class _FakeRegionStorage implements RegionStorage {
  static const poland = Region(
    id: 1,
    parentId: null,
    name: 'Polska',
    type: RegionType.country,
    code: 'PL',
    totalAreaKm2: 312696.0,
    minLat: 49.0,
    maxLat: 55.0,
    minLon: 14.0,
    maxLon: 24.5,
  );

  static const czechia = Region(
    id: 2,
    parentId: null,
    name: 'Czechy',
    type: RegionType.country,
    code: 'CZ',
    totalAreaKm2: 78866.0,
    minLat: 48.5,
    maxLat: 51.1,
    minLon: 12.1,
    maxLon: 18.9,
  );

  static const malopolskie = Region(
    id: 10,
    parentId: 1,
    name: 'Małopolskie',
    type: RegionType.state,
    code: null,
    totalAreaKm2: 15183.0,
    minLat: 49.1,
    maxLat: 50.5,
    minLon: 19.0,
    maxLon: 21.4,
  );

  static const moravskoslezsky = Region(
    id: 20,
    parentId: 2,
    name: 'Moravskoslezský kraj',
    type: RegionType.state,
    code: null,
    totalAreaKm2: 5427.0,
    minLat: 49.4,
    maxLat: 50.4,
    minLon: 17.1,
    maxLon: 18.9,
  );

  static const krakow = Region(
    id: 100,
    parentId: 10,
    name: 'Kraków',
    type: RegionType.city,
    code: null,
    totalAreaKm2: 326.8,
    minLat: 49.95,
    maxLat: 50.15,
    minLon: 19.8,
    maxLon: 20.2,
  );

  static const stareMiasto = Region(
    id: 1001,
    parentId: 100,
    name: 'Stare Miasto',
    type: RegionType.district,
    code: null,
    totalAreaKm2: 5.5,
    minLat: 50.05,
    maxLat: 50.07,
    minLon: 19.93,
    maxLon: 19.95,
  );

  final List<Region> _all = [
    poland,
    czechia,
    malopolskie,
    moravskoslezsky,
    krakow,
    stareMiasto,
  ];

  @override
  Future<void> init() async {}
  @override
  Future<void> close() async {}

  @override
  Future<Region?> findRegionById(int id) async {
    for (final r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<List<Region>> findChildren(int parentId) async {
    return _all.where((r) => r.parentId == parentId).toList();
  }

  @override
  Future<List<Region>> findRegionsByPoint({
    required double lat,
    required double lon,
  }) async => [];

  @override
  Future<List<Region>> findRegionsInBBox({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) async => [];

  @override
  Future<List<Region>> getAncestorChain(int regionId) async {
    final chain = <Region>[];
    var current = await findRegionById(regionId);
    while (current != null) {
      chain.add(current);
      if (current.parentId == null) break;
      current = await findRegionById(current.parentId!);
    }
    return chain;
  }

  @override
  Future<void> insertRegions(Iterable<Region> regions) async {}
}

class _FakeStatisticsStorage implements StatisticsStorage {
  final List<UserRegionStats> _regionStats = [
    const UserRegionStats(
      regionId: 1,
      discoveredAreaM2: 50000.0,
      discoveryPercentage: 0.02,
      visitsCount: 10,
    ),
    const UserRegionStats(
      regionId: 2,
      discoveredAreaM2: 20000.0,
      discoveryPercentage: 0.03,
      visitsCount: 3,
    ),
    const UserRegionStats(
      regionId: 10,
      discoveredAreaM2: 50000.0,
      discoveryPercentage: 0.33,
      visitsCount: 10,
    ),
    const UserRegionStats(
      regionId: 20,
      discoveredAreaM2: 20000.0,
      discoveryPercentage: 0.37,
      visitsCount: 3,
    ),
    const UserRegionStats(
      regionId: 100,
      discoveredAreaM2: 50000.0,
      discoveryPercentage: 1.53,
      visitsCount: 10,
    ),
    const UserRegionStats(
      regionId: 1001,
      discoveredAreaM2: 20000.0,
      discoveryPercentage: 36.3,
      visitsCount: 10,
    ),
  ];

  @override
  Future<void> init() async {}
  @override
  Future<void> close() async {}
  @override
  Future<UserStreakStats> loadStreakStats() async => const UserStreakStats(
    currentOpenStreak: 5,
    maxOpenStreak: 12,
    lastOpenDate: '2026-11-03',
    currentRecordingStreak: 3,
    maxRecordingStreak: 7,
    lastRecordingDate: '2026-11-03',
  );
  @override
  Future<void> saveStreakStats(UserStreakStats stats) async {}

  @override
  Future<UserRegionStats?> getRegionStats(int regionId) async {
    for (final s in _regionStats) {
      if (s.regionId == regionId) return s;
    }
    return null;
  }

  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => _regionStats;

  @override
  Future<void> saveRegionStats(Iterable<UserRegionStats> stats) async {}
  @override
  Future<void> clearRegionStats() async {}
  @override
  Future<int?> getCachedTileRegion({
    required int z,
    required int x,
    required int y,
  }) async => null;
  @override
  Future<void> cacheTileRegion({
    required int z,
    required int x,
    required int y,
    required int regionId,
  }) async {}

  @override
  Future<DailyExplorationStats?> getDailyStats(String date) async => null;

  @override
  Future<List<DailyExplorationStats>> getDailyStatsRange({
    required String fromDate,
    required String toDate,
  }) async {
    return [
      DailyExplorationStats(
        date: fromDate,
        newAreaM2: 50000.0,
        distanceM: 3500.0,
        walkDistanceM: 3500.0,
        newStreetsCount: 12,
      ),
    ];
  }

  @override
  Future<DailyExplorationStats?> getBestDayStats() async =>
      const DailyExplorationStats(date: '2026-11-03', newAreaM2: 50000.0);

  @override
  Future<void> saveDailyStats(DailyExplorationStats stats) async {}

  @override
  Future<double?> getRecord(String key) async => 250.0;

  @override
  Future<UserRecordEntry?> getRecordEntry(String key) async =>
      UserRecordEntry(key: key, value: 250.0, label: 'Kraków', timestampMs: 0);

  @override
  Future<void> setRecordIfMax(
    String key,
    double value, {
    String? label,
    int? timestampMs,
  }) async {}
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Locale locale = const Locale('en'),
    Size size = const Size(1170, 2532),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          regionStorageProvider.overrideWithValue(_FakeRegionStorage()),
          statisticsStorageProvider.overrideWithValue(_FakeStatisticsStorage()),
          completedQuestsCountProvider.overrideWithValue(5),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('StatsScreen tests', () {
    testWidgets('renders all main sections properly in English', (
      tester,
    ) async {
      await pumpScreen(tester, const StatsScreen());

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.byType(StatsPeriodTabs), findsOneWidget);
      expect(find.byType(StatsDateNavigator), findsOneWidget);
      expect(find.byType(StatsMetricTile), findsNWidgets(4));
      expect(find.byType(StatsStreaksCard), findsOneWidget);
      expect(find.text('App opened'), findsOneWidget);
      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.byType(StatsWeeklyChart), findsOneWidget);
      expect(find.byType(StatsCountriesBanner), findsOneWidget);
      expect(find.byType(StatsActivitySection), findsOneWidget);
      expect(find.byType(StatsRecordsGrid), findsOneWidget);
      expect(find.byType(StatsDiscoveryCard), findsOneWidget);
      expect(find.byType(StatsMostVisitedCard), findsOneWidget);

      expect(find.text('New area'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('New streets'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);
    });

    testWidgets('switching period tabs updates selection', (tester) async {
      await pumpScreen(tester, const StatsScreen());

      expect(find.text('Week'), findsOneWidget);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All-Time'));
      await tester.pumpAndSettle();

      expect(find.byType(StatsScreen), findsOneWidget);
    });

    testWidgets('renders Polish localized strings properly', (tester) async {
      await pumpScreen(
        tester,
        const StatsScreen(),
        locale: const Locale('pl'),
      );

      expect(find.text('Statystyki'), findsOneWidget);
      expect(find.text('Nowy teren'), findsOneWidget);
      expect(find.text('Dystans'), findsOneWidget);
      expect(find.text('Nowe ulice'), findsOneWidget);
      expect(find.text('Questy'), findsOneWidget);
      expect(find.byType(StatsStreaksCard), findsOneWidget);
      expect(find.text('Otwarcie aplikacji'), findsOneWidget);
      expect(find.text('Nagrywanie'), findsOneWidget);
      expect(find.text('5 dni'), findsOneWidget);
      expect(find.text('3 dni'), findsOneWidget);
    });
  });

  group('CountriesScreen tests', () {
    testWidgets('renders countries title, summary and country cards', (
      tester,
    ) async {
      await pumpScreen(tester, const CountriesScreen());

      expect(find.text('Countries'), findsOneWidget);
      expect(find.byType(CountryAccordionCard), findsWidgets);
      expect(find.text('Polska'), findsOneWidget);
    });

    testWidgets('expanding country accordion toggles subregions', (
      tester,
    ) async {
      await pumpScreen(tester, const CountriesScreen());

      expect(find.text('Czechy'), findsOneWidget);
      await tester.tap(find.text('Czechy'));
      await tester.pumpAndSettle();

      expect(find.byType(CountryAccordionCard), findsWidgets);
    });
  });

  group('RegionDetailScreen tests', () {
    testWidgets('renders region discovery, metrics, subregions and metadata', (
      tester,
    ) async {
      await pumpScreen(tester, const RegionDetailScreen(regionId: 10));

      expect(find.text('Małopolskie'), findsOneWidget);
      expect(find.byType(StatsDetailProgressCard), findsOneWidget);
      expect(find.byType(StatsMetricsRow), findsOneWidget);
      expect(find.byType(StatsDiscoveryCard), findsOneWidget);
      expect(find.byType(StatsMetadataCard), findsOneWidget);

      expect(find.text('Region discovery'), findsOneWidget);
      expect(find.text('Discovered'), findsOneWidget);
      expect(find.text('Cities'), findsOneWidget);
      expect(find.text('Streets'), findsOneWidget);
    });
  });

  group('CityDetailScreen tests', () {
    testWidgets('renders city discovery, metrics, districts and metadata', (
      tester,
    ) async {
      await pumpScreen(tester, const CityDetailScreen(cityId: 100));

      expect(find.text('Kraków'), findsWidgets);
      expect(find.byType(StatsDetailProgressCard), findsOneWidget);
      expect(find.byType(StatsMetricsRow), findsOneWidget);
      expect(find.byType(StatsDiscoveryCard), findsOneWidget);
      expect(find.byType(StatsMetadataCard), findsOneWidget);

      expect(find.text('City discovery'), findsOneWidget);
      expect(find.text('Discovered'), findsOneWidget);
      expect(find.text('Streets'), findsOneWidget);
      expect(find.text('Routes'), findsOneWidget);
    });
  });
}
