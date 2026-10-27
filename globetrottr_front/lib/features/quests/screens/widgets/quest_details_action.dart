import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';

class QuestDetailsAction extends StatelessWidget {
  final Quest quest;
  final bool isStarting;
  final VoidCallback onStart;

  const QuestDetailsAction({
    super.key,
    required this.quest,
    required this.isStarting,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return switch (quest.zone) {
      QuestZone.unstarted => NeuPrimaryButton(
        onPressed: isStarting ? null : onStart,
        child: isStarting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: AppColors.accentBlue,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Start Quest',
                style: AppTextStyles.submitButtonText,
              ),
      ),
      QuestZone.inProgress => Text(
        '${(quest.progress * 100).toInt()}% progress',
        style: AppTextStyles.rulesetTitle.copyWith(
          color: AppColors.accentBlue,
        ),
      ),
      QuestZone.completed => Text(
        'Completed',
        style: AppTextStyles.rulesetTitle.copyWith(
          color: AppColors.accentGreen,
        ),
      ),
    };
  }
}
