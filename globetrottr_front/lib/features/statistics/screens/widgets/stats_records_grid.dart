import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class RecordTileItem {
  const RecordTileItem({
    required this.header,
    required this.value,
    required this.subtitle,
  });

  final String header;
  final String value;
  final String subtitle;
}

class StatsRecordsGrid extends StatelessWidget {
  const StatsRecordsGrid({
    super.key,
    required this.records,
  });

  final List<RecordTileItem> records;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final record in records)
              SizedBox(
                width: halfWidth,
                child: _buildTile(context, record),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, RecordTileItem item) {
    final palette = context.palette;
    final typography = context.typography;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.header.toUpperCase(),
            style: typography.smallStrong.copyWith(
              fontSize: 11,
              letterSpacing: 0.08 * 11,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            style: typography.itemTitle.copyWith(
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            style: typography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
