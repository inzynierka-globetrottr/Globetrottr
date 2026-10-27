import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker.dart';
import 'package:latlong2/latlong.dart';

class QuestMarkerLayer extends StatelessWidget {
  final List<Quest> quests;
  final int? selectedQuestId;
  final ValueChanged<Quest> onQuestTap;

  const QuestMarkerLayer({
    super.key,
    required this.quests,
    required this.onQuestTap,
    this.selectedQuestId,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final quest in quests)
          if (quest.location case final LatLng location)
            Marker(
              point: location,
              width: MapConfig.questMarkerSize,
              height: MapConfig.questMarkerSize,
              child: GestureDetector(
                onTap: () => onQuestTap(quest),
                child: QuestMarker(
                  zone: quest.zone,
                  isSelected: quest.id == selectedQuestId,
                ),
              ),
            ),
      ],
    );
  }
}
