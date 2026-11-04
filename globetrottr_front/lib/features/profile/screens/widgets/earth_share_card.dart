import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// How much of the Earth's land is discovered, in percent.
class EarthShareCard extends StatelessWidget {
  const EarthShareCard({super.key, required this.percent});

  /// Null while unknown.
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      child: Row(
        spacing: 14,
        children: [
          NeuSurface.circle(
            size: 52,
            shadows: context.shadows.inset(NeoDepth.sm),
            child: Center(
              child: AppIcon(
                AppIcons.earth,
                size: 26,
                color: context.palette.accent,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [
                Text(
                  l10n.profileEarthShareValue(
                    formatSignificant(percent, locale),
                  ),
                  style: typography.title.copyWith(
                    height: 1.15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(l10n.profileEarthShare, style: typography.note),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
