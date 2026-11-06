import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// How much of a route is behind: a sunk track filled with the accent and
/// the percent after it. A new progress is reached gradually.
class QuestRouteBar extends StatelessWidget {
  const QuestRouteBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  static const _height = 12.0;

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.0, 1.0);
    final l10n = context.l10n;
    final motion = context.motion;
    final radius = BorderRadius.circular(_height / 2);
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Semantics(
            value: l10n.mapPercent(formatPercent(fill)),
            child: NeuSurface(
              height: _height,
              borderRadius: radius,
              shadows: context.shadows.inset(NeoDepth.xs),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fill),
                duration: motion.long,
                curve: motion.curve,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.accent,
                    borderRadius: radius,
                  ),
                ),
                builder: (context, shown, bar) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: shown,
                  child: bar,
                ),
              ),
            ),
          ),
        ),
        AnimatedNumber(
          value: fill,
          format: (share) => l10n.mapPercent(formatPercent(share)),
          style: context.typography.action.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
