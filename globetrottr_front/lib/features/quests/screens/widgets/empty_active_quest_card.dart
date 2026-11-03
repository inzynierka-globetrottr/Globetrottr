import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_steps.dart';

/// The place of the active quest while none is active: a dashed outline
/// with muted steps.
class EmptyActiveQuestCard extends StatelessWidget {
  const EmptyActiveQuestCard({super.key});

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    return CustomPaint(
      painter: _DashedOutline(color: palette.divider, radius: _radius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l10n.questsActiveLabel.toUpperCase(),
                  style: typography.sectionLabel.copyWith(
                    color: palette.shared,
                  ),
                ),
                Text(
                  l10n.questsNoActive,
                  style: typography.value.copyWith(color: palette.textMuted),
                ),
              ],
            ),
            const ExcludeSemantics(child: QuestSteps.placeholder()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                AppIcon(
                  AppIcons.navQuests,
                  size: 16,
                  color: palette.textMuted,
                ),
                Flexible(
                  child: Text(l10n.questsPickFromList, style: typography.note),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedOutline extends CustomPainter {
  _DashedOutline({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _stroke = 2.0;
  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) =>
      old.color != color || old.radius != radius;
}
