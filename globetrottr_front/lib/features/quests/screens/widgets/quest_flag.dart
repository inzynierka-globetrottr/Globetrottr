import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_flag_card.dart';

/// The active quest on the map: a flag in a gold progress ring that grows
/// into a card to its right.
class QuestFlag extends StatelessWidget {
  const QuestFlag({
    super.key,
    required this.quest,
    required this.open,
    required this.onToggle,
    required this.onDetails,
  });

  final Quest quest;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onDetails;

  static const size = 44.0;

  /// The ring of the mock-up is drawn in a 56 px box.
  static const _ringBox = 56.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: size,
      child: Stack(
        children: [
          QuestFlagCard(quest: quest, open: open, onDetails: onDetails),
          Semantics(
            button: true,
            expanded: open,
            label: context.l10n.questActive(quest.title),
            child: GestureDetector(
              onTap: onToggle,
              child: NeuSurface.circle(
                shadows: context.shadows.mapControl,
                size: size,
                child: ProgressRing(
                  fill: quest.progress,
                  color: palette.gold,
                  trackColor: palette.divider,
                  radiusRatio: 23 / _ringBox,
                  strokeRatio: 4 / _ringBox,
                  child: const Center(child: AppIcon(AppIcons.flag, size: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
