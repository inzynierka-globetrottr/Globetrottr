import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_zone_style.dart';

class QuestDetailsHeader extends StatelessWidget {
  final Quest quest;

  const QuestDetailsHeader({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(quest.zone.icon, color: quest.zone.color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quest.title, style: AppTextStyles.screenHeaderLarge),
              const SizedBox(height: 4),
              Text(
                quest.isRoute ? 'Follow the route' : 'Visit the points',
                style: AppTextStyles.descriptiveStatusAction,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
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
    );
  }
}
