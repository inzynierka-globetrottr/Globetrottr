import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/map/provider/location_notifier.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:latlong2/latlong.dart';

class FakeLocationNotifier extends LocationNotifier {
  FakeLocationNotifier(this._initial);

  final LatLng? _initial;

  @override
  TrackingState build() => TrackingState(currentPosition: _initial);

  void moveTo(LatLng position) =>
      state = state.copyWith(currentPosition: position);
}

class FakeQuestService extends Fake implements QuestService {
  FakeQuestService(this.quests);

  List<Quest> quests;
  final started = <int>[];
  AppException? failWith;

  @override
  Future<List<Quest>> fetchUserQuests() async {
    final error = failWith;
    if (error != null) throw error;
    return quests;
  }

  @override
  Future<void> startQuest(int questId) async => started.add(questId);
}

Quest testQuest(
  int id, {
  String? title,
  LatLng? location,
  List<QuestWaypoint> waypoints = const [],
  bool isRoute = false,
  bool isStarted = false,
  bool isCompleted = false,
  double progress = 0,
  int rewardPoints = 100,
  DateTime? completedAt,
}) => Quest(
  id: id,
  title: title ?? 'Quest $id',
  type: isRoute ? Quest.routeType : 'VISIT_POINTS',
  rewardPoints: rewardPoints,
  progress: progress,
  isStarted: isStarted,
  isCompleted: isCompleted,
  location: location,
  waypoints: waypoints,
  completedAt: completedAt,
);

List<QuestWaypoint> testWaypoints(List<bool> visited, {double step = 0.001}) =>
    [
      for (var i = 0; i < visited.length; i++)
        QuestWaypoint(
          point: LatLng(50.0 + (i + 1) * step, 19.0),
          visited: visited[i],
        ),
    ];

/// A container with [quests] loaded and the player at [position].
Future<ProviderContainer> createQuestContainer(
  List<Quest> quests, {
  LatLng? position,
  FakeQuestService? service,
}) async {
  final container = ProviderContainer(
    overrides: [
      questServiceProvider.overrideWithValue(
        service ?? FakeQuestService(quests),
      ),
      locationProvider.overrideWith(() => FakeLocationNotifier(position)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(questsProvider.notifier).loadQuests();
  return container;
}
