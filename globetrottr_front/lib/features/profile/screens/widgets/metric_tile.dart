import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// One number of a profile with its icon and what it counts.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final AppIcons icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.lg),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 12,
        children: [
          NeuSurface.circle(
            size: 40,
            shadows: context.shadows.inset(NeoDepth.sm),
            child: Center(
              child: AppIcon(icon, size: 20, color: context.palette.accent),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: typography.stat.copyWith(
                    height: 1.15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, style: typography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
