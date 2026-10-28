import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/config/quest_marker_config.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_zone_style.dart';

class QuestMarker extends StatelessWidget {
  final QuestZone zone;
  final bool isSelected;
  final bool isVisited;

  const QuestMarker({
    super.key,
    required this.zone,
    this.isSelected = false,
    this.isVisited = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVisited ? QuestZone.completed.color : zone.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isSelected
              ? QuestMarkerConfig.markerSelectedBorderWidth
              : QuestMarkerConfig.markerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: QuestMarkerConfig.markerShadowAlpha),
            blurRadius: QuestMarkerConfig.markerShadowBlur,
            spreadRadius: QuestMarkerConfig.markerShadowSpread,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isVisited ? Icons.check_rounded : zone.icon,
          color: color,
          size: QuestMarkerConfig.markerIconSize,
        ),
      ),
    );
  }
}
