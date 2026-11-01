import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/distance_format.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_sheet.dart';

class QuestAccordionSection extends StatelessWidget {
  final String title;
  final QuestZone zone;
  final List<QuestBoardEntry> entries;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int) onStartQuest;

  const QuestAccordionSection({
    super.key,
    required this.title,
    required this.zone,
    required this.entries,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.onStartQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isExpanded
                      ? AppColors.accentBlue
                      : AppColors.textLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: isExpanded
                      ? AppTextStyles.rulesetTitle.copyWith(
                          color: AppColors.accentBlue,
                        )
                      : AppTextStyles.rulesetTitle.copyWith(
                          color: AppColors.textLight,
                        ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isExpanded
                      ? AppColors.accentBlue
                      : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? (entries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          context.l10n.questsNoQuestsInCategory,
                          style: AppTextStyles.descriptiveStatusAction,
                        ),
                      )
                    : Column(
                        children: [
                          for (final entry in entries)
                            QuestCard(
                              quest: entry.quest,
                              zone: zone,
                              distanceLabel: switch (entry.distanceMeters) {
                                final double meters => formatDistance(
                                  meters,
                                  context.l10n,
                                ),
                                null => null,
                              },
                              onStart: () => onStartQuest(entry.quest.id),
                              onTap: () => showQuestDetailsSheet(
                                context,
                                questId: entry.quest.id,
                              ),
                            ),
                        ],
                      ))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
