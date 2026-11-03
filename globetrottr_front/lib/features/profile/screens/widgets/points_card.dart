import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class PointsCard extends StatelessWidget {
  final int totalPoints;

  const PointsCard({super.key, required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.lg),
      borderRadius: BorderRadius.circular(24),
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: context.palette.accent,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.profileTotalPoints, style: typography.body),
              const SizedBox(height: 2),
              Text('$totalPoints', style: typography.digit),
            ],
          ),
        ],
      ),
    );
  }
}
