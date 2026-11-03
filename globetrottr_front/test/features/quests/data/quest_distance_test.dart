import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_distance.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:latlong2/latlong.dart';

const _player = LatLng(50.0, 19.0);

// About 111 m of latitude per 0.001 degree.
const _near = LatLng(50.001, 19.0);
const _far = LatLng(50.005, 19.0);

Quest _quest({
  String type = 'VISIT_POINTS',
  LatLng? location,
  List<QuestWaypoint> waypoints = const [],
}) => Quest(
  id: 1,
  title: 'Quest',
  type: type,
  rewardPoints: 0,
  progress: 0,
  isStarted: false,
  isCompleted: false,
  location: location,
  waypoints: waypoints,
);

void main() {
  group('distanceToQuest', () {
    test('measures to the nearest point that is not visited yet', () {
      final quest = _quest(
        waypoints: const [
          QuestWaypoint(point: _near, visited: true),
          QuestWaypoint(point: _far, visited: false),
        ],
      );

      expect(distanceToQuest(quest, _player), closeTo(556, 2));
    });

    test('measures to the nearest point once every point is visited', () {
      final quest = _quest(
        waypoints: const [
          QuestWaypoint(point: _far, visited: true),
          QuestWaypoint(point: _near, visited: true),
        ],
      );

      expect(distanceToQuest(quest, _player), closeTo(111, 1));
    });

    test('measures a route to its start', () {
      final quest = _quest(
        type: Quest.routeType,
        location: _far,
        waypoints: const [
          QuestWaypoint(point: _far, visited: false),
          QuestWaypoint(point: _near, visited: false),
        ],
      );

      expect(distanceToQuest(quest, _player), closeTo(556, 2));
    });

    test('falls back to the location when there are no waypoints', () {
      final quest = _quest(location: _near);

      expect(distanceToQuest(quest, _player), closeTo(111, 1));
    });

    test('has no distance without any point', () {
      expect(distanceToQuest(_quest(), _player), isNull);
    });
  });

  group('routeLengthMeters', () {
    test('adds up the segments of the route', () {
      final quest = _quest(
        type: Quest.routeType,
        waypoints: const [
          QuestWaypoint(point: _player, visited: false),
          QuestWaypoint(point: _near, visited: false),
          QuestWaypoint(point: _far, visited: false),
        ],
      );

      expect(routeLengthMeters(quest), closeTo(556, 2));
    });

    test('is zero for a single point', () {
      final quest = _quest(
        type: Quest.routeType,
        waypoints: const [QuestWaypoint(point: _player, visited: false)],
      );

      expect(routeLengthMeters(quest), 0);
    });
  });
}
