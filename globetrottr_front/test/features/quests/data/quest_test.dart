import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_waypoint.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> _questJson({
  bool isStarted = false,
  bool isCompleted = false,
  Object? rewardPoints = 250,
  Object? progress = 0,
  Object? description = 'Walk along the river.',
  Object? location = const {'latitude': 50.054, 'longitude': 19.934},
  Object? waypoints = const [
    {'latitude': 50.054, 'longitude': 19.934, 'visited': true},
    {'latitude': 50.053, 'longitude': 19.937},
  ],
}) => {
  'id': 7,
  'title': 'River walk',
  'description': description,
  'type': 'FOLLOW_ROUTE',
  'rewardPoints': rewardPoints,
  'progress': progress,
  'isStarted': isStarted,
  'isCompleted': isCompleted,
  'location': location,
  'waypoints': waypoints,
};

void main() {
  group('Quest.fromJson', () {
    test('parses description, location and waypoints', () {
      final quest = Quest.fromJson(_questJson());

      expect(quest.id, 7);
      expect(quest.description, 'Walk along the river.');
      expect(quest.location, const LatLng(50.054, 19.934));
      const expectedWaypoints = [
        QuestWaypoint(point: LatLng(50.054, 19.934), visited: true),
        QuestWaypoint(point: LatLng(50.053, 19.937), visited: false),
      ];
      expect(quest.waypoints, expectedWaypoints);
      expect(quest.isRoute, isTrue);
    });

    test('tolerates missing description and geometry', () {
      final quest = Quest.fromJson(
        _questJson(description: null, location: null, waypoints: null),
      );

      expect(quest.description, isNull);
      expect(quest.location, isNull);
      expect(quest.waypoints, isEmpty);
    });

    test('defaults missing reward points and progress to zero', () {
      final quest = Quest.fromJson(
        _questJson(rewardPoints: null, progress: null),
      );

      expect(quest.rewardPoints, 0);
      expect(quest.progress, 0.0);
    });
  });

  group('Quest.zone', () {
    test('is unstarted when the quest was not started', () {
      expect(Quest.fromJson(_questJson()).zone, QuestZone.unstarted);
    });

    test('is inProgress when started but not completed', () {
      expect(
        Quest.fromJson(_questJson(isStarted: true)).zone,
        QuestZone.inProgress,
      );
    });

    test('is completed when completed', () {
      expect(
        Quest.fromJson(_questJson(isStarted: true, isCompleted: true)).zone,
        QuestZone.completed,
      );
    });
  });

  group('Quest.completedAt', () {
    test('parses the completion date', () {
      final quest = Quest.fromJson({
        ..._questJson(isStarted: true, isCompleted: true),
        'completedAt': '2026-09-28T17:30:00',
      });

      expect(quest.completedAt, DateTime(2026, 9, 28, 17, 30));
    });

    test('is null when the quest is not completed', () {
      expect(Quest.fromJson(_questJson()).completedAt, isNull);
    });
  });

  group('Quest points', () {
    Quest withVisited(List<bool> visited) => Quest.fromJson(
      _questJson(
        waypoints: [
          for (var i = 0; i < visited.length; i++)
            {
              'latitude': 50.0 + i / 1000,
              'longitude': 19.9,
              'visited': visited[i],
            },
        ],
      ),
    );

    test('counts the visited points', () {
      expect(withVisited([true, true, false, false]).visitedCount, 2);
    });

    test('the next point is the first one not visited yet', () {
      expect(withVisited([true, false, true, false]).nextWaypointIndex, 1);
    });

    test('has no next point once every point is visited', () {
      expect(withVisited([true, true]).nextWaypointIndex, isNull);
    });
  });
}
