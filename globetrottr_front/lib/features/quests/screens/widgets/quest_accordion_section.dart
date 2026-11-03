import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';

class QuestAccordionSection extends StatelessWidget {
  final String title;
  final QuestZone zone;
  final List<Quest> quests;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int) onStartQuest;

  const QuestAccordionSection({
    super.key,
    required this.title,
    required this.zone,
    required this.quests,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.onStartQuest,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isExpanded ? palette.accent : palette.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: context.typography.itemTitle.copyWith(color: color),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: color,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? (quests.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          context.l10n.questsNoQuestsInCategory,
                          style: context.typography.caption,
                        ),
                      )
                    : Column(
                        children: quests
                            .map(
                              (q) => QuestCard(
                                quest: q,
                                zone: zone,
                                onStart: () => onStartQuest(q.id),
                              ),
                            )
                            .toList(),
                      ))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
