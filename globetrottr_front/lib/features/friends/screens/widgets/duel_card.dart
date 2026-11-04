import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/legend_dot.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/duel_row.dart';

/// The user against a friend: area discovered this week, countries and
/// completed quests.
class DuelCard extends StatelessWidget {
  const DuelCard({
    super.key,
    required this.username,
    required this.comparison,
  });

  final String username;
  final FriendComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    String count(num? value) => value?.toString() ?? l10n.friendsLevelUnknown;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.friendDuel, style: typography.value),
                ),
              ),
              LegendDot(
                color: palette.accent,
                spacing: 5,
                child: Text(l10n.friendsYou, style: typography.captionStrong),
              ),
              Flexible(
                child: LegendDot(
                  color: palette.gold,
                  spacing: 5,
                  child: Text(
                    username,
                    style: typography.captionStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          DuelRow(
            label: l10n.friendDuelDiscovered,
            duel: comparison.discoveredThisWeek,
            format: (km2) => l10n.profileArea(
              formatKm2(km2?.toDouble(), locale, decimals: 1),
            ),
          ),
          DuelRow(
            label: l10n.friendDuelCountries,
            duel: comparison.countries,
            format: count,
          ),
          DuelRow(
            label: l10n.friendDuelQuests,
            duel: comparison.quests,
            format: count,
          ),
        ],
      ),
    );
  }
}
