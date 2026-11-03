import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_illustrations.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/app_illustration.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_flag_chip.dart';

class StatsCountriesBanner extends StatelessWidget {
  const StatsCountriesBanner({
    super.key,
    required this.countriesCount,
    required this.regionsCount,
    required this.citiesCount,
    required this.countryCodes,
    required this.onTap,
  });

  final int countriesCount;
  final int regionsCount;
  final int citiesCount;
  final List<String> countryCodes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: NeuSurface(
        shadows: context.shadows.raised(NeoDepth.xl),
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 120,
                height: 160,
                color: context.palette.illustrationBackground,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const AppIllustration(
                      AppIllustrations.viewVoronoi,
                      size: 110,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            palette.background.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$countriesCount',
                    style: typography.display.copyWith(
                      fontSize: 38,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsVisitedCountriesTitle,
                    style: typography.action.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final code in countryCodes.take(4))
                        CountryFlagChip(
                          countryCode: code,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const NeuDivider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.statsCountriesSummary(regionsCount, citiesCount),
                          style: typography.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppIcon(
                        AppIcons.chevronRight,
                        size: 16,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
