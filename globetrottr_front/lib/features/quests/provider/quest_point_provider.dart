import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// The next point of the active quest on the map.
class QuestPoint {
  const QuestPoint({required this.position, this.distanceMeters});

  final LatLng position;
  final double? distanceMeters;
}

// TODO(data): quests have no map points yet; the next point of the active
// quest and its distance from the player.
final questPointProvider = Provider<QuestPoint?>((ref) => null);
