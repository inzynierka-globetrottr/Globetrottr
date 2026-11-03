import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_illustrations.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_illustration.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_accordion_card.dart';
import 'package:go_router/go_router.dart';

class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final typography = context.typography;
    final palette = context.palette;
    final dataAsync = ref.watch(countriesDataProvider);

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
                            l10n.statsCountriesTitle,
                            style: typography.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n.statsCountriesSummary(
                              data.visitedRegionsCount,
                              data.visitedCitiesCount,
                            ),
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
                NeuSurface(
                  shadows: context.shadows.raised(NeoDepth.xl),
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      color: const Color(0xFFB9D2DC),
                      child: const Center(
                        child: AppIllustration(
                          AppIllustrations.viewVoronoi,
                          size: 160,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  l10n.statsVisitedSection(data.countries.length),
                ),
                const SizedBox(height: 12),
                if (data.countries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.statsNoVisitedCountries,
                        style: typography.body.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < data.countries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    CountryAccordionCard(
                      countryCode: data.countries[i].countryCode,
                      countryName: data.countries[i].countryName,
                      subtitle: data.countries[i].subtitle,
                      initiallyExpanded: i == 0,
                      subregions: [
                        for (final sub in data.countries[i].subregions)
                          SubregionItem(
                            id: sub.id,
                            name: sub.name,
                            onTap: () => context.push(
                              '/profile/statistics/region/${sub.id}',
                            ),
                          ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
