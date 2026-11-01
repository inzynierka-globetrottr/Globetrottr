import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

@immutable
class QuestBoardEntry {
  final Quest quest;
  final double? distanceMeters;

  const QuestBoardEntry({required this.quest, this.distanceMeters});
}

/// The quests of the quest board, split by zone and sorted from the nearest.
@immutable
class QuestBoard {
  final List<QuestBoardEntry> unstarted;
  final List<QuestBoardEntry> inProgress;
  final List<QuestBoardEntry> completed;

  const QuestBoard({
    this.unstarted = const [],
    this.inProgress = const [],
    this.completed = const [],
  });
}

final questBoardProvider = Provider<QuestBoard>((ref) {
  final quests = ref.watch(questsProvider.select((state) => state.quests));
  final position = ref.watch(
    locationProvider.select((state) => state.currentPosition),
  );

  List<QuestBoardEntry> entriesIn(QuestZone zone) => _sortedByDistance([
    for (final quest in quests)
      if (quest.zone == zone)
        QuestBoardEntry(
          quest: quest,
          distanceMeters: position == null
              ? null
              : distanceToQuest(quest, position),
        ),
  ]);

  return QuestBoard(
    unstarted: entriesIn(QuestZone.unstarted),
    inProgress: entriesIn(QuestZone.inProgress),
    completed: entriesIn(QuestZone.completed),
  );
});

/// Quests without a distance go last; ties keep a stable order by id.
List<QuestBoardEntry> _sortedByDistance(List<QuestBoardEntry> entries) {
  if (entries.every((entry) => entry.distanceMeters == null)) return entries;
  return entries..sort((a, b) {
    final da = a.distanceMeters;
    final db = b.distanceMeters;
    if (da == null || db == null) {
      if (da == db) return a.quest.id.compareTo(b.quest.id);
      return da == null ? 1 : -1;
    }
    final byDistance = da.compareTo(db);
    return byDistance != 0 ? byDistance : a.quest.id.compareTo(b.quest.id);
  });
}
