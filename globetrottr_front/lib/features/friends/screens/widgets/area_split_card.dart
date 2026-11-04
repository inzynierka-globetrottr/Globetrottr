import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/legend_dot.dart';
import 'package:globetrottr_front/core/widgets/neu_split_bar.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';

/// A map of both discovered areas and how they split into the parts only
/// one of them has seen and the shared part.
class AreaSplitCard extends StatelessWidget {
  const AreaSplitCard({
    super.key,
    required this.username,
    required this.split,
    required this.map,
  });

  final String username;

  /// Null while unknown; the bar stays empty.
  final AreaSplit? split;
  final Widget map;

  static const _mapHeight = 196.0;
  static const _mapRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final caption = context.typography.caption;
    final split = this.split;
    final mapRadius = BorderRadius.circular(_mapRadius);

    Widget legend(Color color, String text) => Flexible(
      child: LegendDot(
        color: color,
        child: Text(text, style: caption, overflow: TextOverflow.ellipsis),
      ),
    );

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SizedBox(
            height: _mapHeight,
            child: ClipRRect(
              borderRadius: mapRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  map,
                  IgnorePointer(
                    child: NeuInsetShadow(
                      shadows: context.shadows.inset(NeoDepth.md),
                      borderRadius: mapRadius,
                    ),
                  ),
                ],
              ),
            ),
          ),
          NeuSplitBar(
            parts: split == null || split.isEmpty
                ? const []
                : [
                    (share: split.onlyMe, color: palette.accent),
                    (share: split.shared, color: palette.shared),
                    (share: split.onlyFriend, color: palette.gold),
                  ],
            semanticLabel: split == null || split.isEmpty
                ? null
                : l10n.friendSplitSummary(
                    formatPercent(split.onlyMe),
                    formatPercent(split.shared),
                    username,
                    formatPercent(split.onlyFriend),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              legend(palette.accent, l10n.friendOnlyYou),
              legend(palette.shared, l10n.friendShared),
              legend(palette.gold, l10n.friendOnlyFriend(username)),
            ],
          ),
        ],
      ),
    );
  }
}
