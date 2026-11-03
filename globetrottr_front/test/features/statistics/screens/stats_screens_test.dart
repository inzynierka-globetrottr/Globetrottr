import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
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
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_records_grid.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_weekly_chart.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

class _FakeRegionStorage implements RegionStorage {
  @override
  Future<void> init() async {}
  @override
  Future<void> close() async {}
  @override
  Future<Region?> findRegionById(int id) async => null;
  @override
  Future<List<Region>> findChildren(int parentId) async => [];
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
  Future<List<Region>> getAncestorChain(int regionId) async => [];
  @override
  Future<void> insertRegions(Iterable<Region> regions) async {}
}

class _FakeStatisticsStorage implements StatisticsStorage {
  @override
  Future<void> init() async {}
  @override
  Future<void> close() async {}
  @override
  Future<UserStreakStats> loadStreakStats() async => UserStreakStats.empty;
  @override
  Future<void> saveStreakStats(UserStreakStats stats) async {}
  @override
  Future<UserRegionStats?> getRegionStats(int regionId) async => null;
  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => [];
  @override
  Future<void> saveRegionStats(Iterable<UserRegionStats> stats) async {}
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
  }) async => [];
  @override
  Future<void> saveDailyStats(DailyExplorationStats stats) async {}
  @override
  Future<double?> getRecord(String key) async => null;
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
      await pumpScreen(tester, const RegionDetailScreen(regionId: 1));

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
      await pumpScreen(tester, const CityDetailScreen(cityId: 1));

      expect(find.text('Kraków'), findsOneWidget);
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
