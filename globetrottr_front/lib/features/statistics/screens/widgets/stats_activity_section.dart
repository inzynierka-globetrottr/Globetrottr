import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class ActivityDistanceItem {
  const ActivityDistanceItem({
    required this.label,
    required this.distanceKm,
    required this.percentage,
  });

  final String label;
  final double distanceKm;
  final double percentage; // 0.0 to 1.0
}

class StatsActivitySection extends StatelessWidget {
  const StatsActivitySection({
    super.key,
    required this.activities,
  });

  final List<ActivityDistanceItem> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < activities.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildRow(context, activities[i]),
        ],
      ],
    );
  }

  Widget _buildRow(BuildContext context, ActivityDistanceItem item) {
    final palette = context.palette;
    final typography = context.typography;
    final fillFraction = item.percentage.clamp(0.02, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            item.label,
            style: typography.action.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 14,
            child: NeuSurface(
              shadows: context.shadows.inset(NeoDepth.sm),
              borderRadius: BorderRadius.circular(7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            item.distanceKm.round().toString(),
            textAlign: TextAlign.right,
            style: typography.action.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
