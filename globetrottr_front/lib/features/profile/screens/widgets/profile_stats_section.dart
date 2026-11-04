import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/earth_share_card.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/metric_tile.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/weekly_area_chart.dart';

/// The statistics both the own profile and a friend's show: new area per
/// week, distance, completed quests and the share of the Earth's land.
class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final quests = stats.completedQuests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        WeeklyAreaChart(weeklyKm2: stats.weeklyKm2),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: MetricTile(
                icon: AppIcons.distance,
                value: l10n.profileDistanceValue(
                  formatNumber(stats.distanceKm, locale),
                ),
                label: l10n.profileDistance,
              ),
            ),
            Expanded(
              child: MetricTile(
                icon: AppIcons.flag,
                value: quests?.toString() ?? l10n.friendsLevelUnknown,
                label: l10n.profileCompletedQuests,
              ),
            ),
          ],
        ),
        EarthShareCard(percent: stats.earthLandPercent),
      ],
    );
  }
}
