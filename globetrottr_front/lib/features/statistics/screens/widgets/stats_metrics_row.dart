import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class StatMetricItem {
  const StatMetricItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class StatsMetricsRow extends StatelessWidget {
  const StatsMetricsRow({
    super.key,
    required this.metrics,
  });

  final List<StatMetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _buildMetricTile(context, metrics[i])),
        ],
      ],
    );
  }

  Widget _buildMetricTile(BuildContext context, StatMetricItem item) {
    final palette = context.palette;
    final typography = context.typography;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: typography.valueLarge.copyWith(
              height: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: typography.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
