import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_split_bar.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';

/// One value of a duel: the user's on the left, the friend's on the right,
/// a tick at the better one and a bar split between them.
class DuelRow extends StatelessWidget {
  const DuelRow({
    super.key,
    required this.label,
    required this.duel,
    required this.format,
  });

  final String label;
  final Duel duel;
  final String Function(num? value) format;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final share = duel.myShare;
    final leader = duel.leader;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Value(
                  text: format(duel.me),
                  leads: leader == DuelSide.me,
                  color: palette.accent,
                ),
              ),
            ),
            Text(label.toUpperCase(), style: context.typography.sectionLabel),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _Value(
                  text: format(duel.friend),
                  leads: leader == DuelSide.friend,
                  color: palette.text,
                ),
              ),
            ),
          ],
        ),
        NeuSplitBar(
          parts: share == null
              ? const []
              : [
                  (share: share, color: palette.accent),
                  (share: 1 - share, color: palette.gold),
                ],
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.text, required this.leads, required this.color});

  final String text;
  final bool leads;

  /// The colour of the value and its tick when it [leads].
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.value.copyWith(
      color: leads ? color : null,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (leads)
          Semantics(
            label: context.l10n.friendDuelBetter,
            child: AppIcon(AppIcons.check, size: 14, color: color),
          ),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
