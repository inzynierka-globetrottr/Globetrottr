import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

enum StatsActivityType { walk, bike, run, other }

class ActivityDistanceItem {
  const ActivityDistanceItem({
    required this.label,
    required this.distanceKm,
    required this.percentage,
    this.type,
  });

  final String label;
  final double distanceKm;
  final double percentage; // 0.0 to 1.0
  final StatsActivityType? type;
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
            _labelFor(context, item),
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
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            item.distanceKm.round().toString(),
            textAlign: TextAlign.right,
            maxLines: 1,
            style: typography.action.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(BuildContext context, ActivityDistanceItem item) {
    final l10n = context.l10n;
    switch (item.type) {
      case StatsActivityType.walk:
        return l10n.statsActivityWalk;
      case StatsActivityType.bike:
        return l10n.statsActivityBike;
      case StatsActivityType.run:
        return l10n.statsActivityRun;
      case StatsActivityType.other:
        return l10n.statsActivityOther;
      case null:
        return item.label;
    }
  }
}
