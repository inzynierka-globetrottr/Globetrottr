import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';

enum QuestZone { unstarted, inProgress, completed }

class QuestCard extends StatelessWidget {
  final Quest quest;
  final QuestZone zone;
  final VoidCallback? onStart;

  const QuestCard({
    super.key,
    required this.quest,
    required this.zone,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeuSurface(
        shadows: context.shadows.raised(NeoDepth.lg),
        borderRadius: BorderRadius.circular(24),
        height: zone == QuestZone.unstarted ? 140 : 90,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: typography.itemTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (zone == QuestZone.inProgress)
                        Text(
                          l10n.questsProgressPercent(
                            (quest.progress * 100).toInt(),
                          ),
                          style: typography.caption.copyWith(
                            color: palette.accent,
                          ),
                        ),
                      if (zone == QuestZone.completed)
                        Text(
                          l10n.questsCompletedStatus,
                          style: typography.caption.copyWith(
                            color: palette.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: palette.gold,
                      size: 24,
                    ),
                    Text(
                      l10n.questsRewardXp(quest.rewardPoints),
                      style: typography.smallStrong.copyWith(
                        color: palette.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (zone == QuestZone.unstarted) ...[
              const Spacer(),
              NeuButton(
                height: 36,
                depth: NeoDepth.sm,
                onPressed: onStart,
                child: Text(
                  l10n.questsStartQuest,
                  style: typography.label.copyWith(color: palette.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
