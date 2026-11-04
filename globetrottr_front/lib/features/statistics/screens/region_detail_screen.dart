import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_not_found_screen.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_routes.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_detail_progress_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_labels.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metadata_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metrics_row.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_attribution.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_screen_header.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class RegionDetailScreen extends ConsumerWidget {
  const RegionDetailScreen({super.key, required this.regionId});

  final int regionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final dataAsync = ref.watch(regionDetailProvider(regionId));

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
                        subtitle: _subtitle(l10n, language, data),
                      ),
                      const SizedBox(height: 16),
                      StatsDetailProgressCard(
                        title: l10n.statsRegionDiscoveryTitle,
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
                          StatMetricItem(
                            value: '${data.citiesCount}',
                            label: l10n.statsMetricCities,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SectionHeader(switch (data.subregionKind) {
                        RegionType.district =>
                          l10n.statsDistrictsDiscoveryTitle,
                        RegionType.city => l10n.statsSubregionsDiscoveryTitle,
                        _ => l10n.statsCountiesDiscoveryTitle,
                      }),
                      const SizedBox(height: 12),
                      StatsDiscoveryCard(
                        barHeight: 8,
                        emptyMessage: l10n.statsNoSubregions,
                        items: [
                          for (final sub in data.subregions)
                            DiscoveryRowItem(
                              id: sub.id,
                              name: sub.name.of(language),
                              percentage: sub.percentage,
                              subtitle: sub.details.isEmpty
                                  ? null
                                  : sub.details
                                        .map((n) => n.of(language))
                                        .join(', '),
                              onTap: switch (statsRouteFor(sub.type, sub.id)) {
                                final route? => () => context.push(route),
                                null => null,
                              },
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

  static String _subtitle(
    AppLocalizations l10n,
    String language,
    RegionDetailData data,
  ) {
    final discovered = data.discoveredSubregionsCount;
    final total = data.totalSubregionsCount;
    final count = switch (data.subregionKind) {
      RegionType.district => l10n.statsDistrictsCount(discovered, total),
      RegionType.city => l10n.statsCitiesCount(discovered, total),
      _ => l10n.statsCountiesCount(discovered, total),
    };
    final country = data.countryName?.of(language);
    return country == null ? count : '$country · $count';
  }
}
