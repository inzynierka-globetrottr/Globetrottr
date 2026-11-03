import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// How much of a route is behind: a sunk track filled with the accent and
/// the percent after it.
class QuestRouteBar extends StatelessWidget {
  const QuestRouteBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  static const _height = 12.0;

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.0, 1.0);
    final percent = formatPercent(fill);
    final radius = BorderRadius.circular(_height / 2);
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Semantics(
            value: context.l10n.mapPercent(percent),
            child: NeuSurface(
              height: _height,
              borderRadius: radius,
              shadows: context.shadows.inset(NeoDepth.xs),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.accent,
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          context.l10n.mapPercent(percent),
          style: context.typography.action.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
