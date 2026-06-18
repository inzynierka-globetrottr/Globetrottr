import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/quests/models/quest.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeuFloatingContainer(
        width: double.infinity,
        height: zone == QuestZone.unstarted ? 140 : 90,
        child: Padding(
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
                          style: AppTextStyles.actionButtonText,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (zone == QuestZone.inProgress)
                          Text(
                            '${(quest.progress * 100).toInt()}% progress',
                            style: AppTextStyles.descriptiveStatusAction
                                .copyWith(color: AppColors.accentBlue),
                          ),
                        if (zone == QuestZone.completed)
                          Text(
                            'Completed',
                            style: AppTextStyles.descriptiveStatusAction
                                .copyWith(color: AppColors.accentGreen),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accentGold,
                        size: 24,
                      ),
                      Text(
                        '${quest.rewardPoints} XP',
                        style: AppTextStyles.inputLabel.copyWith(
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (zone == QuestZone.unstarted) ...[
                const Spacer(),
                NeuPrimaryButton(
                  height: 36,
                  label: 'Start Quest',
                  labelStyle: AppTextStyles.tabButtonText.copyWith(
                    color: AppColors.accentBlue,
                  ),
                  onPressed: onStart,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
