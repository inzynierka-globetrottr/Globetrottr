import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_flag.dart';

/// The card that grows out of the quest flag: the quest's name, its
/// progress and a button to its details.
class QuestFlagCard extends StatelessWidget {
  const QuestFlagCard({
    super.key,
    required this.quest,
    required this.open,
    required this.onDetails,
  });

  final Quest quest;
  final bool open;
  final VoidCallback onDetails;

  static const _grow = Duration(milliseconds: 280);
  static const _fade = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return AnimatedContainer(
          duration: _grow,
          curve: Curves.ease,
          width: open ? fullWidth : QuestFlag.size,
          height: QuestFlag.size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(QuestFlag.size / 2),
            boxShadow: [
              if (open)
                for (final s in context.shadows.mapControl) s.toBoxShadow(),
            ],
          ),
          // The content keeps its full width while the card grows, so it is
          // uncovered instead of squeezed.
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: fullWidth,
            maxWidth: fullWidth,
            child: AnimatedOpacity(
              duration: _fade,
              opacity: open ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 54, right: 8),
                child: Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text(
                            quest.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.label,
                          ),
                          // TODO(data): "point 4/5 · 280 m" and its bar of
                          // points once quests have map points.
                          Text(
                            context.l10n.questProgressShort(
                              formatPercent(quest.progress),
                            ),
                            style: typography.smallStrong.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    NeuIconButton(
                      size: 32,
                      fill: NeuFill.accent,
                      semanticLabel: context.l10n.questDetails,
                      onPressed: open ? onDetails : null,
                      child: const AppIcon(AppIcons.chevronRight, size: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
