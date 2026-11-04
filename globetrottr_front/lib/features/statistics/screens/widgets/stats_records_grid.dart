import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

enum StatsRecordType { longestRoute, bestDay }

class RecordTileItem {
  const RecordTileItem({
    required this.header,
    required this.value,
    required this.subtitle,
    this.type,
  });

  final String header;
  final String value;
  final String subtitle;
  final StatsRecordType? type;
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
            _headerFor(context, item),
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

  String _headerFor(BuildContext context, RecordTileItem item) {
    final l10n = context.l10n;
    switch (item.type) {
      case StatsRecordType.longestRoute:
        return l10n.statsRecordLongestRoute.toUpperCase();
      case StatsRecordType.bestDay:
        return l10n.statsRecordBestDay.toUpperCase();
      case null:
        return item.header.toUpperCase();
    }
  }
}
