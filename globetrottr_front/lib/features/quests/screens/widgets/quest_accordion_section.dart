import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';

class QuestAccordionSection extends StatelessWidget {
  final String title;
  final QuestZone zone;
  final List<Quest> quests;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int) onStartQuest;

  const QuestAccordionSection({
    super.key,
    required this.title,
    required this.zone,
    required this.quests,
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
              ? (quests.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No quests in this category.',
                          style: AppTextStyles.descriptiveStatusAction,
                        ),
                      )
                    : Column(
                        children: quests
                            .map(
                              (q) => QuestCard(
                                quest: q,
                                zone: zone,
                                onStart: () => onStartQuest(q.id),
                              ),
                            )
                            .toList(),
                      ))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
