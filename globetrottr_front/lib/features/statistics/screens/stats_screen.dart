import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_overview_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_routes.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_countries_banner.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_date_navigator.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_labels.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metric_tile.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_period_tabs.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_records_grid.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_streaks_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_weekly_chart.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_screen_header.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final overviewAsync = ref.watch(statsOverviewProvider);

    return Scaffold(
      body: SafeArea(
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text(l10n.errorSomethingWentWrong)),
          data: (state) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatsScreenHeader(
                  title: l10n.statsTitle,
                  subtitle: statsPeriodLabel(l10n, locale, state.range),
                ),
                const SizedBox(height: 16),
                StatsPeriodTabs(
                  selectedPeriod: state.period,
                  onPeriodChanged: (p) =>
                      ref.read(statsOverviewProvider.notifier).setPeriod(p),
                ),
                const SizedBox(height: 16),
                StatsDateNavigator(
                  label: statsPeriodLabel(l10n, locale, state.range),
                  onPrevious: () =>
                      ref.read(statsOverviewProvider.notifier).previousPeriod(),
                  onNext: () =>
                      ref.read(statsOverviewProvider.notifier).nextPeriod(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatsMetricTile(
                        label: l10n.statsNewArea,
                        value: '${formatKm2(state.newAreaKm2, locale)} km²',
                        isAccent: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsMetricTile(
                        label: l10n.statsDistance,
                        value:
                            '${formatKm2(state.distanceKm, locale, decimals: 1)} km',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StatsMetricTile(
                  label: l10n.statsQuests,
                  value: '${state.questsCount}',
                ),
                const SizedBox(height: 12),
                StatsStreaksCard(
                  openStreakDays: state.openStreakDays,
                  maxOpenStreakDays: state.maxOpenStreakDays,
                  recordingStreakDays: state.recordingStreakDays,
                  maxRecordingStreakDays: state.maxRecordingStreakDays,
                ),
                const SizedBox(height: 16),
                StatsWeeklyChart(bars: state.weeklyBars),
                const SizedBox(height: 16),
                StatsCountriesBanner(
                  countriesCount: state.visitedCountriesCount,
                  regionsCount: state.visitedRegionsCount,
                  citiesCount: state.visitedCitiesCount,
                  countryCodes: state.countryCodes,
                  onTap: () => context.push('/profile/statistics/countries'),
                ),
                const SizedBox(height: 20),
                SectionHeader(l10n.statsRecordsTitle),
                const SizedBox(height: 12),
                StatsRecordsGrid(records: state.records),
                const SizedBox(height: 20),
                SectionHeader(l10n.statsCitiesDiscoveryTitle),
                const SizedBox(height: 12),
                StatsDiscoveryCard(
                  emptyMessage: l10n.statsNoDiscoveredCities,
                  items: [
                    for (final city in state.discoveredCities)
                      DiscoveryRowItem(
                        id: city.id,
                        name: city.name.of(language),
                        percentage: city.percentage,
                        onTap: () => context.push(
                          statsRouteFor(city.type, city.id)!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
