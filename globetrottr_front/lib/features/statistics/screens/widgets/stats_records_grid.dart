import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

enum StatsRecordType { longestRoute, bestDay }

class RecordTileItem {
  const RecordTileItem({
    required this.type,
    this.value,
    this.date,
    this.label,
  });

  final StatsRecordType type;

  /// Metres for the longest route, km² for the best day; null without a
  /// record.
  final double? value;
  final DateTime? date;
  final String? label;
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
    final locale = Localizations.localeOf(context).toString();

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
              letterSpacing: 0.08 * 11,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _valueFor(locale, item),
            style: typography.statValue.copyWith(
              height: 1.25,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitleFor(locale, item),
            style: typography.caption.copyWith(
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
    return switch (item.type) {
      StatsRecordType.longestRoute => l10n.statsRecordLongestRoute,
      StatsRecordType.bestDay => l10n.statsRecordBestDay,
    }.toUpperCase();
  }

  String _valueFor(String locale, RecordTileItem item) {
    final value = item.value;
    if (value == null) return _none;
    return switch (item.type) {
      StatsRecordType.longestRoute => formatDistance(value, locale),
      StatsRecordType.bestDay => '+${formatKm2(value, locale)} km²',
    };
  }

  String _subtitleFor(String locale, RecordTileItem item) {
    if (item.label != null) return item.label!;
    final date = item.date;
    return date == null ? _none : formatShortDate(date, locale);
  }

  static const _none = '–';
}
