import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';
import 'package:latlong2/latlong.dart';

/// The next point of the active quest on the map.
class QuestPoint {
  const QuestPoint({
    required this.position,
    this.distanceMeters,
    this.index = 0,
    this.total = 1,
  });

  final LatLng position;
  final double? distanceMeters;

  /// Which point it is (from 0) out of [total].
  final int index;
  final int total;
}

/// Only quests of places have a next point; a route is drawn as a line.
final questPointProvider = Provider<QuestPoint?>((ref) {
  final quest = ref.watch(activeQuestProvider);
  if (quest == null || quest.isRoute) return null;
  final index = quest.nextWaypointIndex;
  if (index == null) return null;
  final position = quest.waypoints[index].point;
  final player = ref.watch(
    locationProvider.select((state) => state.currentPosition),
  );
  return QuestPoint(
    position: position,
    distanceMeters: player == null ? null : metersBetween(player, position),
    index: index,
    total: quest.waypoints.length,
  );
});
