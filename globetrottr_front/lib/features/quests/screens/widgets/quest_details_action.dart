import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
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
    final l10n = context.l10n;
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
            : Text(
                l10n.questsStartQuest,
                style: AppTextStyles.submitButtonText,
              ),
      ),
      QuestZone.inProgress => Text(
        l10n.questsProgressPercent((quest.progress * 100).toInt()),
        style: AppTextStyles.rulesetTitle.copyWith(
          color: AppColors.accentBlue,
        ),
      ),
      QuestZone.completed => Text(
        l10n.questsCompletedStatus,
        style: AppTextStyles.rulesetTitle.copyWith(
          color: AppColors.accentGreen,
        ),
      ),
    };
  }
}
