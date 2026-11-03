import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class StatsMetricTile extends StatelessWidget {
  const StatsMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  final String label;
  final String value;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;

    return NeuSurface(
      shadows: context.shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: typography.caption.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: typography.titleLarge.copyWith(
              fontSize: 24,
              letterSpacing: -0.02 * 24,
              color: isAccent ? palette.accent : palette.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
