import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker_layer.dart';
import 'package:latlong2/latlong.dart';

const _center = LatLng(50.0614, 19.9383);

Quest _quest(int id, {LatLng? location}) => Quest(
  id: id,
  title: 'Quest $id',
  type: 'VISIT_POINTS',
  rewardPoints: 100,
  progress: 0,
  isStarted: false,
  isCompleted: false,
  location: location,
);

Future<void> _pumpLayer(
  WidgetTester tester, {
  required List<Quest> quests,
  required ValueChanged<Quest> onQuestTap,
  int? selectedQuestId,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: FlutterMap(
        options: const MapOptions(initialCenter: _center, initialZoom: 16),
        children: [
          QuestMarkerLayer(
            quests: quests,
            selectedQuestId: selectedQuestId,
            onQuestTap: onQuestTap,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('renders a marker only for quests with a location', (
    tester,
  ) async {
    await _pumpLayer(
      tester,
      quests: [
        _quest(1, location: _center),
        _quest(2),
      ],
      onQuestTap: (_) {},
    );

    expect(find.byType(QuestMarker), findsOneWidget);
  });

  testWidgets('reports the tapped quest', (tester) async {
    Quest? tapped;
    await _pumpLayer(
      tester,
      quests: [_quest(7, location: _center)],
      onQuestTap: (quest) => tapped = quest,
    );

    await tester.tap(find.byType(QuestMarker));

    expect(tapped?.id, 7);
  });

  testWidgets('highlights only the selected quest', (tester) async {
    await _pumpLayer(
      tester,
      quests: [
        _quest(1, location: _center),
        _quest(2, location: const LatLng(50.0616, 19.9385)),
      ],
      selectedQuestId: 2,
      onQuestTap: (_) {},
    );

    final markers = tester.widgetList<QuestMarker>(find.byType(QuestMarker));
    expect(markers.where((marker) => marker.isSelected), hasLength(1));
  });
}
