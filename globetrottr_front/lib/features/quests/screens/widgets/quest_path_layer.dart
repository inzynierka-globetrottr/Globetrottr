import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/config/quest_marker_config.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_zone_style.dart';

class QuestPathLayer extends StatelessWidget {
  final Quest quest;

  const QuestPathLayer({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    final color = quest.zone.color;

    if (quest.isRoute) {
      return PolylineLayer(
        polylines: [
          Polyline(
            points: quest.waypoints,
            color: color,
            strokeWidth: QuestMarkerConfig.routeStrokeWidth,
          ),
        ],
      );
    }

    return CircleLayer(
      circles: [
        for (final point in quest.waypoints)
          CircleMarker(
            point: point,
            radius: QuestMarkerConfig.pointRadius,
            color: color.withValues(alpha: QuestMarkerConfig.pointFillAlpha),
            borderColor: color,
            borderStrokeWidth: QuestMarkerConfig.pointBorderWidth,
          ),
      ],
    );
  }
}
