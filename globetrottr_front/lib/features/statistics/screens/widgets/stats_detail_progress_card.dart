import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class StatsDetailProgressCard extends StatelessWidget {
  const StatsDetailProgressCard({
    super.key,
    required this.title,
    required this.percentage, // 0.0 to 100.0 (or share 0.0 to 1.0)
  });

  final String title;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();

    final percentValue = percentage <= 1.0 ? percentage * 100 : percentage;
    final fillFraction = (percentValue / 100).clamp(0.01, 1.0);
    final formattedPercent =
        '${formatKm2(percentValue, locale, decimals: percentValue < 1 ? 2 : 1)}%';

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: typography.itemTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedPercent,
                style: typography.itemTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
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
        ],
      ),
    );
  }
}
