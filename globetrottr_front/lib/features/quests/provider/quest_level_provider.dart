import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

/// The player's level on the Quests tab.
@immutable
class QuestLevel {
  const QuestLevel({this.level, this.xp, this.nextLevelXp, this.completed});

  /// Null while unknown.
  final int? level;
  final int? xp;
  final int? nextLevelXp;

  /// Null until the quests are loaded.
  final int? completed;

  /// How far the player is to the next level, from 0 to 1.
  double get fill {
    final xp = this.xp;
    final next = nextLevelXp;
    if (xp == null || next == null || next <= 0) return 0;
    return (xp / next).clamp(0.0, 1.0);
  }
}

// TODO(data): the backend has no levels yet; the level and the XP needed for
// the next one. The XP is the profile's total points.
final questLevelProvider = Provider<QuestLevel>((ref) {
  final xp = ref.watch(
    profileProvider.select((state) => state.profile?.totalPoints),
  );
  final completed = ref.watch(
    questsProvider.select(
      (state) => state.hasLoaded
          ? state.quests.where((quest) => quest.isCompleted).length
          : null,
    ),
  );
  return QuestLevel(xp: xp, completed: completed);
});
