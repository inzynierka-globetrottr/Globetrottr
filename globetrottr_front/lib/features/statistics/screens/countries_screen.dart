import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/provider/region_detail_provider.dart';
import 'package:globetrottr_front/features/statistics/screens/stats_routes.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_accordion_card.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_attribution.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/stats_screen_header.dart';
import 'package:go_router/go_router.dart';

class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final typography = context.typography;
    final palette = context.palette;
    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final dataAsync = ref.watch(countriesDataProvider);

    return Scaffold(
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text(l10n.errorSomethingWentWrong)),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatsScreenHeader(
                  title: l10n.statsCountriesTitle,
                  subtitle: l10n.statsCountriesSummary(
                    data.visitedRegionsCount,
                    data.visitedCitiesCount,
                  ),
                ),
                const SizedBox(height: 16),
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
                      countryName: data.countries[i].countryName.of(language),
                      subtitle: l10n.statsCountryCardSubtitle(
                        formatKm2(
                          data.countries[i].areaKm2,
                          locale,
                          decimals: 1,
                        ),
                        data.countries[i].citiesCount,
                      ),
                      initiallyExpanded: i == 0,
                      groups: [
                        for (final state in data.countries[i].states)
                          SubregionGroup(
                            header: SubregionItem(
                              id: state.id,
                              name: state.name.of(language),
                              onTap: () => context.push(
                                statsRouteFor(RegionType.state, state.id)!,
                              ),
                            ),
                            items: [
                              for (final city in state.cities)
                                SubregionItem(
                                  id: city.id,
                                  name: city.name.of(language),
                                  onTap: () => context.push(
                                    statsRouteFor(city.type, city.id)!,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
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
