import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_detail_progress_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_discovery_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metadata_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_metrics_row.dart';

class CityDetailScreen extends ConsumerWidget {
  const CityDetailScreen({super.key, required this.cityId});

  final int cityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    final dataAsync = ref.watch(cityDetailProvider(cityId));

    return Scaffold(
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text(err.toString())),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const NeuBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            style: typography.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${data.regionName} · miasto',
                            style: typography.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  items: data.districts,
                ),
                const SizedBox(height: 16),
                StatsMetadataCard(
                  rows: [
                    MetadataRowItem(
                      label: l10n.statsFirstVisit,
                      value: data.firstVisit,
                    ),
                    MetadataRowItem(
                      label: l10n.statsLastVisit,
                      value: data.lastVisit,
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
