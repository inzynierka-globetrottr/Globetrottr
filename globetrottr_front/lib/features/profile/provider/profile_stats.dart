import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/geo/earth.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quest_level_provider.dart';

/// What a profile shows, the user's own or a friend's. Unknown values are
/// null and are shown as neutral placeholders.
@immutable
class ProfileStats {
  const ProfileStats({
    this.level = const QuestLevel(),
    this.rank,
    this.totalKm2,
    this.weeklyKm2 = noWeeks,
    this.distanceKm,
    this.completedQuests,
    this.friendsSince,
  });

  /// How many weeks the weekly chart shows, the current one included.
  static const weeksShown = 8;

  static const noWeeks = <double?>[
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];

  final QuestLevel level;

  /// The name of the level, e.g. "Cartographer".
  final String? rank;

  /// The whole discovered area.
  final double? totalKm2;

  /// Area discovered for the first time in each of the last [weeksShown]
  /// weeks, oldest first; the last one is the current week.
  final List<double?> weeklyKm2;
  final double? distanceKm;
  final int? completedQuests;

  /// When the friendship started; only on a friend's profile.
  final DateTime? friendsSince;

  /// The discovered part of the Earth's land, in percent.
  double? get earthLandPercent {
    final km2 = totalKm2;
    return km2 == null ? null : km2 / earthLandAreaKm2 * 100;
  }
}

// TODO(data): the rank name, the weekly area and the distance from the
// bitmap fog and the track log, the XP of the next level from the backend.
final myProfileStatsProvider = Provider<ProfileStats>((ref) {
  final level = ref.watch(questLevelProvider);
  return ProfileStats(
    level: level,
    totalKm2: ref.watch(myActivityProvider).totalKm2,
    completedQuests: level.completed,
  );
});

// TODO(data): the friend's XP, rank, weekly area, distance, completed quests
// and the date the friendship started, from the backend.
final friendProfileStatsProvider = Provider.family<ProfileStats, String>((
  ref,
  username,
) {
  final activity = ref.watch(friendActivityProvider(username));
  return ProfileStats(
    level: QuestLevel(level: activity.level),
    totalKm2: activity.totalKm2,
  );
});
