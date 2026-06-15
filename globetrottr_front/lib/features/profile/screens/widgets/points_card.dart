import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';

class PointsCard extends StatelessWidget {
  final int totalPoints;

  const PointsCard({
    super.key,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return NeuFloatingContainer(
      width: double.infinity,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.accentBlue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Points',
                style: AppTextStyles.inputLabel.copyWith(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalPoints',
                style: AppTextStyles.screenHeaderLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}