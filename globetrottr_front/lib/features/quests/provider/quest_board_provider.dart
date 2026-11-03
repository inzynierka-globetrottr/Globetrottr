import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:latlong2/latlong.dart';

/// The lists of the Quests tab: the quests that can be started, grouped by
/// type and nearest first, and the completed ones, newest first. The active
/// quest has its own card.
@immutable
class QuestBoard {
  final List<Quest> places;
  final List<Quest> routes;
  final List<Quest> completed;

  const QuestBoard({
    this.places = const [],
    this.routes = const [],
    this.completed = const [],
  });
}

final questBoardProvider = Provider<QuestBoard>((ref) {
  final quests = ref.watch(questsProvider.select((state) => state.quests));
  final position = ref.watch(
    locationProvider.select((state) => state.currentPosition),
  );
  final available = _nearestFirst([
    for (final quest in quests)
      if (!quest.isStarted) quest,
  ], position);
  return QuestBoard(
    places: [
      for (final quest in available)
        if (!quest.isRoute) quest,
    ],
    routes: [
      for (final quest in available)
        if (quest.isRoute) quest,
    ],
    completed: [
      for (final quest in quests)
        if (quest.isCompleted) quest,
    ]..sort(_newestFirst),
  );
});

/// Quests without a point go last; ties keep a stable order by id. Without a
/// position the server order stays.
List<Quest> _nearestFirst(List<Quest> quests, LatLng? position) {
  if (position == null) return quests;
  final distances = {
    for (final quest in quests) quest.id: distanceToQuest(quest, position),
  };
  return quests..sort((a, b) {
    final da = distances[a.id];
    final db = distances[b.id];
    if (da == null || db == null) {
      if (da == db) return a.id.compareTo(b.id);
      return da == null ? 1 : -1;
    }
    final byDistance = da.compareTo(db);
    return byDistance != 0 ? byDistance : a.id.compareTo(b.id);
  });
}

int _newestFirst(Quest a, Quest b) {
  final da = a.completedAt;
  final db = b.completedAt;
  if (da == null || db == null) {
    if (da == db) return a.id.compareTo(b.id);
    return da == null ? 1 : -1;
  }
  return db.compareTo(da);
}
