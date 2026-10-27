import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:latlong2/latlong.dart';

class Quest {
  static const String routeType = 'FOLLOW_ROUTE';

  final int id;
  final String title;
  final String? description;
  final String type;
  final int rewardPoints;
  final double progress;
  final bool isStarted;
  final bool isCompleted;
  final LatLng? location;
  final List<LatLng> waypoints;

  const Quest({
    required this.id,
    required this.title,
    required this.type,
    required this.rewardPoints,
    required this.progress,
    required this.isStarted,
    required this.isCompleted,
    this.description,
    this.location,
    this.waypoints = const [],
  });

  bool get isRoute => type == routeType;

  QuestZone get zone {
    if (isCompleted) return QuestZone.completed;
    if (isStarted) return QuestZone.inProgress;
    return QuestZone.unstarted;
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final waypoints = json['waypoints'];
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      rewardPoints: json['rewardPoints'],
      progress: (json['progress'] as num).toDouble(),
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      location: location is Map<String, dynamic>
          ? _latLngFromJson(location)
          : null,
      waypoints: waypoints is List
          ? waypoints
                .whereType<Map<String, dynamic>>()
                .map(_latLngFromJson)
                .toList()
          : const [],
    );
  }

  static LatLng _latLngFromJson(Map<String, dynamic> json) => LatLng(
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
  );
}
