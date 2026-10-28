import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/provider/selected_quest_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_sheet.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_map_layers.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_marker.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_path_layer.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

const _mapCenter = LatLng(50.0614, 19.9383);
const _questLocation = LatLng(50.0620, 19.9390);

class _FakeQuestService implements QuestService {
  _FakeQuestService(this.quests);

  final List<Quest> quests;

  @override
  Future<List<Quest>> fetchUserQuests() async => quests;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Quest _quest(int id, {bool isStarted = false, LatLng? location}) => Quest(
  id: id,
  title: 'Quest $id',
  type: 'VISIT_POINTS',
  rewardPoints: 100,
  progress: 0,
  isStarted: isStarted,
  isCompleted: false,
  location: location,
  waypoints: [
    if (location != null) QuestWaypoint(point: location, visited: false),
  ],
);

Future<(ProviderContainer, MapController)> _pumpLayers(
  WidgetTester tester,
  List<Quest> quests,
) async {
  final container = ProviderContainer(
    overrides: [
      questServiceProvider.overrideWithValue(_FakeQuestService(quests)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(questsProvider.notifier).loadQuests();

  final mapController = MapController();
  addTearDown(mapController.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 16,
            ),
            children: const [QuestMapLayers()],
          ),
        ),
      ),
    ),
  );
  return (container, mapController);
}

void main() {
  testWidgets('keeps the selected quest path after the sheet is dismissed', (
    tester,
  ) async {
    final (container, _) = await _pumpLayers(tester, [
      _quest(1, location: _questLocation),
    ]);

    await tester.tap(find.byType(QuestMarker));
    await tester.pumpAndSettle();
    expect(find.byType(QuestDetailsSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(QuestDetailsSheet), findsNothing);
    expect(container.read(selectedQuestIdProvider), 1);
    expect(find.byType(QuestPathLayer), findsOneWidget);
  });

  testWidgets('hides the path once the selection is cleared', (tester) async {
    final quest = _quest(1, location: _questLocation);
    final (container, _) = await _pumpLayers(tester, [quest]);
    container.read(selectedQuestIdProvider.notifier).select(quest);
    await tester.pump();
    expect(find.byType(QuestPathLayer), findsOneWidget);

    container.read(selectedQuestIdProvider.notifier).clear();
    await tester.pump();

    expect(find.byType(QuestPathLayer), findsNothing);
  });

  testWidgets('always shows paths of quests in progress', (tester) async {
    await _pumpLayers(tester, [
      _quest(1, location: _questLocation),
      _quest(2, isStarted: true, location: _mapCenter),
    ]);

    final paths = tester.widgetList<QuestPathLayer>(
      find.byType(QuestPathLayer),
    );
    expect(paths.map((path) => path.quest.id), [2]);
  });

  testWidgets('centers the camera on the tapped quest', (tester) async {
    final (_, mapController) = await _pumpLayers(tester, [
      _quest(1, location: _questLocation),
    ]);

    await tester.tap(find.byType(QuestMarker));
    await tester.pumpAndSettle();

    expect(mapController.camera.center, _questLocation);
  });
}
