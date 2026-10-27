import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';

extension QuestZoneStyle on QuestZone {
  Color get color => switch (this) {
    QuestZone.unstarted => AppColors.accentGold,
    QuestZone.inProgress => AppColors.accentBlue,
    QuestZone.completed => AppColors.accentGreen,
  };

  IconData get icon => switch (this) {
    QuestZone.unstarted => Icons.explore_outlined,
    QuestZone.inProgress => Icons.run_circle_outlined,
    QuestZone.completed => Icons.emoji_events_outlined,
  };
}
