import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_progress_bar.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';
import 'package:intl/intl.dart';

/// The level behind a profile's avatar: its name, the XP towards the next
/// level and, on a friend's profile, since when they are friends.
class LevelDetailsCard extends StatelessWidget {
  const LevelDetailsCard({
    super.key,
    required this.stats,
    this.isFriend = false,
  });

  final ProfileStats stats;
  final bool isFriend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    final level = stats.level;
    final levelText = l10n.questsLevel(
      level.level?.toString() ?? l10n.friendsLevelUnknown,
    );
    final rank = stats.rank;
    final xp = level.xp;
    final next = level.nextLevelXp;
    String number(int value) =>
        NumberFormat.decimalPattern(locale).format(value);

    final xpText = xp != null && next != null
        ? l10n.profileXpProgress(number(xp), number(next))
        : l10n.questsXp(xp == null ? l10n.friendsLevelUnknown : number(xp));
    final friendsSince = stats.friendsSince;
    final currentLevel = level.level;
    final note = isFriend
        ? (friendsSince == null
              ? null
              : l10n.profileFriendsSince(formatSinceDate(friendsSince, locale)))
        : (xp == null || next == null || currentLevel == null
              ? null
              : l10n.profileXpToNext(number(next - xp), currentLevel + 1));
    final tabular = typography.note.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          _Ends(
            start: Text(rank ?? levelText, style: typography.value),
            end: rank == null ? null : Text(levelText, style: typography.note),
          ),
          NeuProgressBar(progress: level.fill),
          _Ends(
            start: Text(xpText, style: tabular),
            end: note == null ? null : Text(note, style: typography.note),
          ),
        ],
      ),
    );
  }
}

class _Ends extends StatelessWidget {
  const _Ends({required this.start, this.end});

  final Widget start;
  final Widget? end;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    spacing: 10,
    children: [
      Flexible(child: start),
      if (end != null) Flexible(child: end!),
    ],
  );
}
