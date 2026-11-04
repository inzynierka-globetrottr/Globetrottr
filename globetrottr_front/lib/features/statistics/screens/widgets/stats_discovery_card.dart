import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class DiscoveryRowItem {
  const DiscoveryRowItem({
    this.id,
    required this.name,
    required this.percentage,
    this.subtitle,
    this.onTap,
  });

  final int? id;
  final String name;
  final double percentage;
  final String? subtitle;
  final VoidCallback? onTap;
}

class StatsDiscoveryCard extends StatelessWidget {
  const StatsDiscoveryCard({
    super.key,
    required this.items,
    this.barHeight = 12,
    this.emptyMessage,
  });

  final List<DiscoveryRowItem> items;
  final double barHeight;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return NeuSurface(
        shadows: context.shadows.raised(NeoDepth.xl),
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: Text(
            emptyMessage ?? '—',
            style: context.typography.body.copyWith(
              color: context.palette.textMuted,
            ),
          ),
        ),
      );
    }

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const NeuDivider(),
            _buildRow(context, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, DiscoveryRowItem item) {
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();

    final percentValue = item.percentage.clamp(0.0, 100.0);
    final fillFraction = (percentValue / 100).clamp(
      percentValue > 0 ? 0.01 : 0.0,
      1.0,
    );
    final formattedPercent =
        '${formatKm2(percentValue, locale, decimals: percentValue > 0 && percentValue < 1 ? 2 : 1)}%';

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
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
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: typography.itemTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formattedPercent,
                      style: typography.itemTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: barHeight,
                  child: NeuSurface(
                    shadows: context.shadows.inset(NeoDepth.sm),
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fillFraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(barHeight / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.onTap != null) ...[
            const SizedBox(width: 12),
            AppIcon(
              AppIcons.chevronRight,
              size: 16,
              color: palette.textMuted,
            ),
          ],
        ],
      ),
    );

    if (item.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.onTap,
        child: content,
      );
    }

    return content;
  }
}
