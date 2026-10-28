import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/config/quest_marker_config.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker.dart';
import 'package:latlong2/latlong.dart';

typedef QuestTapCallback = void Function(Quest quest, LatLng point);

class QuestMarkerLayer extends StatelessWidget {
  final List<Quest> quests;
  final int? selectedQuestId;
  final QuestTapCallback onQuestTap;

  const QuestMarkerLayer({
    super.key,
    required this.quests,
    required this.onQuestTap,
    this.selectedQuestId,
  });

  /// Visit points quests get a pin per target; routes keep a single start pin.
  static List<QuestWaypoint> _pinsOf(Quest quest) {
    if (!quest.isRoute && quest.waypoints.isNotEmpty) return quest.waypoints;
    if (quest.location case final LatLng location) {
      return [QuestWaypoint(point: location, visited: false)];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final quest in quests)
          for (final pin in _pinsOf(quest))
            Marker(
              point: pin.point,
              width: QuestMarkerConfig.markerSize,
              height: QuestMarkerConfig.markerSize,
              child: GestureDetector(
                onTap: () => onQuestTap(quest, pin.point),
                child: QuestMarker(
                  zone: quest.zone,
                  isSelected: quest.id == selectedQuestId,
                  isVisited: pin.visited,
                ),
              ),
            ),
      ],
    );
  }
}
