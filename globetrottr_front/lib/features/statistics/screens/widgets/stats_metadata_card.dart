import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class MetadataRowItem {
  const MetadataRowItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class StatsMetadataCard extends StatelessWidget {
  const StatsMetadataCard({
    super.key,
    required this.rows,
  });

  final List<MetadataRowItem> rows;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const NeuDivider(),
            _buildRow(context, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, MetadataRowItem item) {
    final palette = context.palette;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: typography.note.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: typography.action.copyWith(
                color: palette.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
