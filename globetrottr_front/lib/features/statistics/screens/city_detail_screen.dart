import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_not_found_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_detail_progress_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_labels.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metadata_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metrics_row.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_attribution.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_screen_header.dart';

class CityDetailScreen extends ConsumerWidget {
  const CityDetailScreen({super.key, required this.cityId});

  final int cityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final dataAsync = ref.watch(cityDetailProvider(cityId));

    return Scaffold(
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text(l10n.errorSomethingWentWrong)),
          data: (data) => data == null
              ? const StatsNotFoundScreen()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatsScreenHeader(
                        title: data.name.of(language),
                        subtitle: l10n.statsCitySubtitle(
                          data.regionName?.of(language) ?? '–',
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatsDetailProgressCard(
                        title: l10n.statsCityDiscoveryTitle,
                        percentage: data.discoveryPercentage,
                      ),
                      const SizedBox(height: 16),
                      StatsMetricsRow(
                        metrics: [
                          StatMetricItem(
                            value:
                                '${formatKm2(data.discoveredAreaKm2, locale, decimals: data.discoveredAreaKm2 > 0 && data.discoveredAreaKm2 < 0.1 ? 2 : 1)} km²',
                            label: l10n.statsMetricDiscovered,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SectionHeader(l10n.statsDistrictsDiscoveryTitle),
                      const SizedBox(height: 12),
                      StatsDiscoveryCard(
                        barHeight: 8,
                        emptyMessage: l10n.statsNoSubregions,
                        items: [
                          for (final district in data.districts)
                            DiscoveryRowItem(
                              id: district.id,
                              name: district.name.of(language),
                              percentage: district.percentage,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StatsMetadataCard(
                        rows: [
                          MetadataRowItem(
                            label: l10n.statsFirstVisit,
                            value: statsVisitDateLabel(
                              l10n,
                              locale,
                              data.firstVisit,
                            ),
                          ),
                          MetadataRowItem(
                            label: l10n.statsLastVisit,
                            value: statsVisitDateLabel(
                              l10n,
                              locale,
                              data.lastVisit,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const StatsAttribution(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
