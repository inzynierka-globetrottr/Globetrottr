import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker_layer.dart';
import 'package:latlong2/latlong.dart';

const _center = LatLng(50.0614, 19.9383);

Quest _quest(
  int id, {
  String type = 'VISIT_POINTS',
  LatLng? location,
  List<QuestWaypoint> waypoints = const [],
}) => Quest(
  id: id,
  title: 'Quest $id',
  type: type,
  rewardPoints: 100,
  progress: 0,
  isStarted: false,
  isCompleted: false,
  location: location,
  waypoints: waypoints,
);

const _points = [
  QuestWaypoint(point: LatLng(50.0614, 19.9383), visited: true),
  QuestWaypoint(point: LatLng(50.0616, 19.9385), visited: false),
  QuestWaypoint(point: LatLng(50.0618, 19.9387), visited: false),
];

Future<void> _pumpLayer(
  WidgetTester tester, {
  required List<Quest> quests,
  required QuestTapCallback onQuestTap,
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
      onQuestTap: (_, _) {},
    );

    expect(find.byType(QuestMarker), findsOneWidget);
  });

  testWidgets('renders a marker for every point of a visit points quest', (
    tester,
  ) async {
    await _pumpLayer(
      tester,
      quests: [_quest(1, location: _center, waypoints: _points)],
      onQuestTap: (_, _) {},
    );

    final markers = tester.widgetList<QuestMarker>(find.byType(QuestMarker));
    expect(markers.map((marker) => marker.isVisited), [true, false, false]);
  });

  testWidgets('renders a single start marker for a route quest', (
    tester,
  ) async {
    await _pumpLayer(
      tester,
      quests: [
        _quest(1, type: Quest.routeType, location: _center, waypoints: _points),
      ],
      onQuestTap: (_, _) {},
    );

    expect(find.byType(QuestMarker), findsOneWidget);
  });

  testWidgets('reports the tapped point', (tester) async {
    LatLng? tappedPoint;
    await _pumpLayer(
      tester,
      quests: [
        _quest(1, waypoints: [_points[1]]),
      ],
      onQuestTap: (_, point) => tappedPoint = point,
    );

    await tester.tap(find.byType(QuestMarker));

    expect(tappedPoint, _points[1].point);
  });

  testWidgets('reports the tapped quest', (tester) async {
    Quest? tapped;
    await _pumpLayer(
      tester,
      quests: [_quest(7, location: _center)],
      onQuestTap: (quest, _) => tapped = quest,
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
      onQuestTap: (_, _) {},
    );

    final markers = tester.widgetList<QuestMarker>(find.byType(QuestMarker));
    expect(markers.where((marker) => marker.isSelected), hasLength(1));
  });
}
