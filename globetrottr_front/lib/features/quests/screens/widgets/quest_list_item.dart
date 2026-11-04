import 'dart:math';

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_map_preview.dart';

/// A quest of a list that opens into a map preview. An available quest has
/// a button on the preview that starts it; a completed one says when it was
/// completed instead of its size.
class QuestListItem extends StatelessWidget {
  const QuestListItem({
    super.key,
    required this.quest,
    required this.expanded,
    required this.onToggle,
    this.onStart,
    this.swaps = false,
  });

  final Quest quest;
  final bool expanded;
  final VoidCallback onToggle;

  /// Null for a completed quest.
  final VoidCallback? onStart;

  /// Starting it replaces the active quest.
  final bool swaps;

  static const _toggle = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                spacing: 12,
                children: [
                  if (quest.isCompleted)
                    _CompletedBadge(quest: quest)
                  else
                    _TypeTile(quest: quest),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(quest.title, style: typography.itemTitle),
                        _Subtitle(quest: quest),
                      ],
                    ),
                  ),
                  if (!quest.isCompleted)
                    Text(
                      l10n.questsRewardXp(quest.rewardPoints),
                      style: typography.action,
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _toggle,
          curve: Curves.ease,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Stack(
                    children: [
                      QuestMapPreview(quest: quest),
                      if (onStart != null)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: NeuIconButton(
                            fill: NeuFill.accent,
                            semanticLabel: swaps
                                ? l10n.questsSwap(quest.title)
                                : l10n.questsStart(quest.title),
                            onPressed: onStart,
                            child: const AppIcon(AppIcons.footsteps),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.quest});

  final Quest quest;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) => NeuSurface(
    width: _size,
    height: _size,
    borderRadius: BorderRadius.circular(12),
    shadows: context.shadows.inset(NeoDepth.sm),
    child: Center(
      child: AppIcon(
        quest.isRoute ? AppIcons.route : AppIcons.pin,
        size: 20,
        color: context.palette.accent,
      ),
    ),
  );
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) => NeuSurface.circle(
    size: _TypeTile._size,
    color: context.palette.gold,
    shadows: const [],
    child: Center(
      child: AppIcon(quest.isRoute ? AppIcons.route : AppIcons.pin, size: 20),
    ),
  );
}

/// The points as dots or the route as a short bar, with their count or
/// length; for a completed quest its type and the day it was completed.
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.quest});

  final Quest quest;

  static const _dot = 7.0;
  static const _maxDots = 5;
  static const _bar = Size(26, 4);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final style = context.typography.note;
    final locale = Localizations.localeOf(context).toString();
    if (quest.isCompleted) {
      final type = quest.isRoute ? l10n.questsRoutes : l10n.questsPlaces;
      final date = quest.completedAt;
      return Text(
        date == null
            ? type
            : l10n.questsCompletedOn(type, formatShortDate(date, locale)),
        style: style,
      );
    }
    final points = quest.waypoints.length;
    return Row(
      spacing: 8,
      children: [
        ExcludeSemantics(
          child: quest.isRoute
              ? Container(
                  width: _bar.width,
                  height: _bar.height,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(_bar.height / 2),
                  ),
                )
              : Row(
                  spacing: 4,
                  children: [
                    for (var i = 0; i < min(max(points, 1), _maxDots); i++)
                      Container(
                        width: _dot,
                        height: _dot,
                        decoration: BoxDecoration(
                          color: palette.divider,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
        ),
        Text(
          quest.isRoute
              ? l10n.questsKilometers(
                  formatKm2(
                    routeLengthMeters(quest) / 1000,
                    locale,
                    decimals: 1,
                  ),
                )
              : l10n.questsPointCount(points == 0 ? 1 : points),
          style: style,
        ),
      ],
    );
  }
}
