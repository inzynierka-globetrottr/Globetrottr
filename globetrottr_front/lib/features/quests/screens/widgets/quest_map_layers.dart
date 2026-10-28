import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/provider/selected_quest_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_sheet.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker_layer.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_path_layer.dart';
import 'package:latlong2/latlong.dart';

/// Must be placed inside [FlutterMap.children], as it moves the map camera.
class QuestMapLayers extends ConsumerWidget {
  const QuestMapLayers({super.key});

  void _openQuest(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    LatLng point,
  ) {
    ref.read(selectedQuestIdProvider.notifier).select(quest);
    MapController.of(context).move(point, MapCamera.of(context).zoom);
    showQuestDetailsSheet(context, questId: quest.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider.select((state) => state.quests));
    final selectedQuestId = ref.watch(selectedQuestIdProvider);
    final questsWithPath = quests.where(
      (quest) =>
          quest.id == selectedQuestId || quest.zone == QuestZone.inProgress,
    );

    return Stack(
      children: [
        for (final quest in questsWithPath) QuestPathLayer(quest: quest),
        QuestMarkerLayer(
          quests: quests,
          selectedQuestId: selectedQuestId,
          onQuestTap: (quest, point) => _openQuest(context, ref, quest, point),
        ),
      ],
    );
  }
}
