import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/active_quest_card.dart';

/// Asks whether to give up [active] and its progress for [next]. True when
/// the player agrees.
Future<bool> confirmQuestSwap(
  BuildContext context, {
  required Quest active,
  required Quest next,
}) async {
  final swap = await showDialog<bool>(
    context: context,
    builder: (_) => QuestSwapDialog(active: active, next: next),
  );
  return swap ?? false;
}

class QuestSwapDialog extends StatelessWidget {
  const QuestSwapDialog({super.key, required this.active, required this.next});

  final Quest active;
  final Quest next;

  static const _icon = 60.0;

  String _progress(BuildContext context) {
    if (active.isRoute) return questProgressText(context, active);
    final total = active.waypoints.length;
    final current = (active.nextWaypointIndex ?? total - 1) + 1;
    return context.l10n.questsSwapProgressPoint(current, total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            NeuSurface.circle(
              size: _icon,
              shadows: context.shadows.inset(NeoDepth.sm),
              child: Center(
                child: AppIcon(
                  AppIcons.warning,
                  size: 28,
                  color: palette.danger,
                ),
              ),
            ),
            Text(
              l10n.questsSwapTitle,
              style: typography.title,
              textAlign: TextAlign.center,
            ),
            Text(
              l10n.questsSwapBody(active.title, _progress(context), next.title),
              style: typography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: NeuButton(
                    height: NeuPrimarySize.medium.height,
                    depth: NeoDepth.md,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.questsSwapCancel, style: typography.value),
                  ),
                ),
                Expanded(
                  child: NeuPrimaryButton(
                    label: l10n.questsSwapConfirm,
                    size: NeuPrimarySize.medium,
                    danger: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
