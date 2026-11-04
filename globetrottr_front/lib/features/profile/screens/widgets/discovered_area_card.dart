import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// The whole discovered area on an accent card. With a [map] the map sits
/// on top of the card; without one a map icon closes the row.
class DiscoveredAreaCard extends StatelessWidget {
  const DiscoveredAreaCard({super.key, required this.totalKm2, this.map});

  /// Null while unknown.
  final double? totalKm2;
  final Widget? map;

  static const _radius = 22.0;
  static const mapHeight = 196.0;
  static const _icon = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final onAccent = palette.onAccent;
    final locale = Localizations.localeOf(context).toString();
    final area = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.profileArea(formatKm2(totalKm2, locale, decimals: 1)),
          style: typography.headline.copyWith(
            color: onAccent,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          l10n.profileDiscovered,
          style: typography.note.copyWith(
            color: onAccent.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
    final radius = BorderRadius.circular(_radius);
    final map = this.map;

    if (map == null) {
      return NeuSurface(
        shadows: context.shadows.raisedAccent(NeoDepth.lg),
        borderRadius: radius,
        color: palette.accent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            Expanded(child: area),
            NeuSurface.circle(
              size: _icon,
              shadows: const [],
              color: onAccent.withValues(alpha: 0.16),
              child: Center(
                child: AppIcon(AppIcons.map, size: 24, color: onAccent),
              ),
            ),
          ],
        ),
      );
    }
    return NeuSurface(
      shadows: context.shadows.raisedAccent(NeoDepth.lg),
      borderRadius: radius,
      color: palette.accent,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: mapHeight, child: map),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: area,
            ),
          ],
        ),
      ),
    );
  }
}
