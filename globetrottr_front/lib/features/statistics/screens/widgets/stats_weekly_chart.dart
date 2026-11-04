import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class WeeklyBarItem {
  const WeeklyBarItem({
    required this.isoWeek,
    required this.valueKm2,
    this.isCurrent = false,
  });

  final int isoWeek;
  final double valueKm2;
  final bool isCurrent;
}

class StatsWeeklyChart extends StatelessWidget {
  const StatsWeeklyChart({
    super.key,
    required this.bars,
  });

  final List<WeeklyBarItem> bars;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();

    final maxValue = bars.fold<double>(
      0.1,
      (prev, bar) => math.max(prev, bar.valueKm2),
    );
    const chartHeight = 78.0;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.statsWeeklyNewArea,
                  style: typography.value,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.statsWeeklyChartUnitKm2,
                style: typography.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildBarColumn(
                      context,
                      bars[i],
                      maxValue,
                      chartHeight,
                      locale,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < bars.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bars[i].isCurrent
                        ? l10n.statsCurrentWeek
                        : '${bars[i].isoWeek}',
                    textAlign: TextAlign.center,
                    style: typography.small.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(
    BuildContext context,
    WeeklyBarItem item,
    double maxValue,
    double chartHeight,
    String locale,
  ) {
    final palette = context.palette;
    final typography = context.typography;
    final barHeight = ((item.valueKm2 / maxValue) * chartHeight).clamp(
      12.0,
      chartHeight,
    );
    final formattedValue = formatKm2(item.valueKm2, locale);
    final barColor = item.isCurrent ? palette.gold : palette.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          formattedValue,
          style: typography.micro.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              for (final s in context.shadows.raised(NeoDepth.xs))
                s.toBoxShadow(),
            ],
          ),
        ),
      ],
    );
  }
}
