import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';
import 'package:globetrottr_front/features/quests/provider/quest_level_provider.dart';

/// The player's level in a ring, their XP and completed quests; opens the
/// history of completed quests.
class QuestLevelRow extends StatelessWidget {
  const QuestLevelRow({super.key, required this.level, required this.onTap});

  final QuestLevel level;
  final VoidCallback onTap;

  static const _ring = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final levelText = level.level?.toString() ?? l10n.friendsLevelUnknown;
    final completedCount = level.completed;
    final completed = completedCount == null
        ? l10n.friendsLevelUnknown
        : l10n.questsCompletedCount(completedCount);
    return Semantics(
      button: true,
      label: l10n.questsHistoryLink(levelText, completed),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            spacing: 16,
            children: [
              NeuSurface.circle(
                size: _ring,
                shadows: context.shadows.inset(NeoDepth.sm),
                child: ProgressRing(
                  fill: level.fill,
                  color: palette.accent,
                  radiusRatio: 31 / _ring,
                  strokeRatio: 5 / _ring,
                  child: Center(
                    child: Text(
                      levelText,
                      style: typography.titleLarge.copyWith(
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(l10n.questsLevel(levelText), style: typography.value),
                    AnimatedNumber(
                      value: level.xp?.toDouble(),
                      format: (xp) => l10n.questsXp(
                        xp?.round().toString() ?? l10n.friendsLevelUnknown,
                      ),
                      style: typography.note.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      completed,
                      style: typography.label.copyWith(color: palette.accent),
                    ),
                  ],
                ),
              ),
              AppIcon(
                AppIcons.chevronRight,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
