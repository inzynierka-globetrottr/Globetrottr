import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:latlong2/latlong.dart';

const _distance = Distance();

/// Meters from [from] to the nearest point of [quest] the player still has to
/// reach: the start of a route, or the nearest point not visited yet. A quest
/// with every point visited measures to its nearest point.
double? distanceToQuest(Quest quest, LatLng from) {
  final targets = _targetsOf(quest);
  if (targets.isEmpty) return null;
  return targets
      .map((point) => _distance.as(LengthUnit.Meter, from, point))
      .reduce((a, b) => a < b ? a : b);
}

List<LatLng> _targetsOf(Quest quest) {
  final waypoints = quest.waypoints;
  if (quest.isRoute || waypoints.isEmpty) {
    if (quest.location case final LatLng start) return [start];
    return [if (waypoints.isNotEmpty) waypoints.first.point];
  }
  final ahead = [
    for (final waypoint in waypoints)
      if (!waypoint.visited) waypoint.point,
  ];
  return ahead.isNotEmpty
      ? ahead
      : [for (final waypoint in waypoints) waypoint.point];
}
