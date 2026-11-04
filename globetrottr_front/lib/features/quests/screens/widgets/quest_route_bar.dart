import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_progress_bar.dart';

/// How much of a route is behind: a progress bar and the percent after it.
class QuestRouteBar extends StatelessWidget {
  const QuestRouteBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.0, 1.0);
    final percent = context.l10n.mapPercent(formatPercent(fill));
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Semantics(
            value: percent,
            child: NeuProgressBar(progress: fill),
          ),
        ),
        Text(
          percent,
          style: context.typography.action.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
