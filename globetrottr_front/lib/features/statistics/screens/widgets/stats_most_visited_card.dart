import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class MostVisitedItem {
  const MostVisitedItem({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

class StatsMostVisitedCard extends StatelessWidget {
  const StatsMostVisitedCard({
    super.key,
    required this.items,
  });

  final List<MostVisitedItem> items;

  @override
  Widget build(BuildContext context) {
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

  Widget _buildRow(BuildContext context, MostVisitedItem item) {
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.name,
              style: typography.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.palette.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.count.toString(),
            style: typography.itemTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
