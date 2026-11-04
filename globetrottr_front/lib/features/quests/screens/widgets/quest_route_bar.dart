import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';
import 'package:globetrottr_front/core/widgets/neu_progress_bar.dart';

/// How much of a route is behind: a progress bar and the percent after it.
/// A new progress is reached gradually.
class QuestRouteBar extends StatelessWidget {
  const QuestRouteBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.0, 1.0);
    final l10n = context.l10n;
    final motion = context.motion;
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Semantics(
            value: l10n.mapPercent(formatPercent(fill)),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fill),
              duration: motion.long,
              curve: motion.curve,
              builder: (context, shown, _) => NeuProgressBar(progress: shown),
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
