import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

@immutable
class QuestWaypoint {
  final LatLng point;
  final bool visited;

  const QuestWaypoint({required this.point, required this.visited});

  factory QuestWaypoint.fromJson(Map<String, dynamic> json) => QuestWaypoint(
    point: LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    ),
    visited: json['visited'] ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is QuestWaypoint &&
      other.point == point &&
      other.visited == visited;

  @override
  int get hashCode => Object.hash(point, visited);
}
