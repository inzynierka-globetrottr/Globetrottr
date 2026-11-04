import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quest_point_provider.dart';
import 'package:latlong2/latlong.dart';

import '../quest_test_support.dart';

const _player = LatLng(50.0, 19.0);

void main() {
  group('questPointProvider', () {
    test('is the next point of the active quest with its distance', () async {
      final container = await createQuestContainer([
        testQuest(
          1,
          isStarted: true,
          waypoints: testWaypoints([true, false, false]),
        ),
      ], position: _player);

      final point = container.read(questPointProvider)!;

      expect(point.position, const LatLng(50.002, 19.0));
      expect(point.index, 1);
      expect(point.total, 3);
      expect(point.distanceMeters, closeTo(222, 2));
    });

    test('has no distance while the position is unknown', () async {
      final container = await createQuestContainer([
        testQuest(1, isStarted: true, waypoints: testWaypoints([false])),
      ]);

      expect(container.read(questPointProvider)!.distanceMeters, isNull);
    });

    test('follows the player', () async {
      final container = await createQuestContainer([
        testQuest(1, isStarted: true, waypoints: testWaypoints([false])),
      ], position: _player);

      (container.read(locationProvider.notifier) as FakeLocationNotifier)
          .moveTo(const LatLng(50.001, 19.0));

      expect(container.read(questPointProvider)!.distanceMeters, closeTo(0, 1));
    });

    test('is empty without an active quest', () async {
      final container = await createQuestContainer([
        testQuest(1, waypoints: testWaypoints([false])),
      ], position: _player);

      expect(container.read(questPointProvider), isNull);
    });

    test('is empty for a route, which is drawn as a line', () async {
      final container = await createQuestContainer([
        testQuest(
          1,
          isRoute: true,
          isStarted: true,
          waypoints: testWaypoints([false, false]),
        ),
      ], position: _player);

      expect(container.read(questPointProvider), isNull);
    });

    test('is empty once every point is visited', () async {
      final container = await createQuestContainer([
        testQuest(1, isStarted: true, waypoints: testWaypoints([true])),
      ], position: _player);

      expect(container.read(questPointProvider), isNull);
    });
  });
}
