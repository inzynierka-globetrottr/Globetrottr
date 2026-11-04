import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/legend_dot.dart';
import 'package:globetrottr_front/core/widgets/neu_split_bar.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';

/// The discovered area split into only the user's, the shared and only the
/// friend's part: a bar and its legend.
class AreaSplitSummary extends StatelessWidget {
  const AreaSplitSummary({
    super.key,
    required this.username,
    required this.split,
  });

  final String username;

  /// Null while unknown; the bar stays empty.
  final AreaSplit? split;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final caption = context.typography.caption;
    final split = this.split;
    final known = split != null && !split.isEmpty;

    Widget legend(Color color, String text) => Flexible(
      child: LegendDot(
        color: color,
        child: Text(text, style: caption, overflow: TextOverflow.ellipsis),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        NeuSplitBar(
          parts: known
              ? [
                  (share: split.onlyMe, color: palette.accent),
                  (share: split.shared, color: palette.shared),
                  (share: split.onlyFriend, color: palette.gold),
                ]
              : const [],
          semanticLabel: known
              ? l10n.friendSplitSummary(
                  formatPercent(split.onlyMe),
                  formatPercent(split.shared),
                  username,
                  formatPercent(split.onlyFriend),
                )
              : null,
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
    );
  }
}
