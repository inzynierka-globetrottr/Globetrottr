import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_route_bar.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_steps.dart';

/// The active quest on top of the Quests tab: its points as steps, or a
/// route as a bar, and a button that shows it on the map.
class ActiveQuestCard extends StatelessWidget {
  const ActiveQuestCard({super.key, required this.quest, required this.onShow});

  final Quest quest;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.questsActiveLabel.toUpperCase(),
                      style: typography.sectionLabel.copyWith(
                        color: palette.accent,
                      ),
                    ),
                    Text(quest.title, style: typography.value),
                    Text(
                      questProgressText(context, quest),
                      style: typography.note.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.questsRewardXp(quest.rewardPoints),
                style: typography.action,
              ),
            ],
          ),
          if (quest.isRoute)
            QuestRouteBar(progress: quest.progress)
          else
            QuestSteps(
              visited: [for (final w in quest.waypoints) w.visited],
              next: quest.nextWaypointIndex,
            ),
          NeuPrimaryButton(
            label: quest.isRoute ? l10n.questsShowRoute : l10n.questsShowPoint,
            icon: quest.isRoute ? AppIcons.route : AppIcons.pin,
            size: NeuPrimarySize.medium,
            onPressed: onShow,
          ),
        ],
      ),
    );
  }
}

/// "Point 4 of 5" for places, "2.7 of 4.2 km" for a route.
String questProgressText(BuildContext context, Quest quest) {
  final l10n = context.l10n;
  if (quest.isRoute) {
    final locale = Localizations.localeOf(context).toString();
    final totalKm = routeLengthMeters(quest) / 1000;
    return l10n.questsRouteDone(
      formatKm2(totalKm * quest.progress.clamp(0.0, 1.0), locale, decimals: 1),
      formatKm2(totalKm, locale, decimals: 1),
    );
  }
  final total = quest.waypoints.length;
  final current = (quest.nextWaypointIndex ?? total - 1) + 1;
  return l10n.questsPointOf(current, total);
}
