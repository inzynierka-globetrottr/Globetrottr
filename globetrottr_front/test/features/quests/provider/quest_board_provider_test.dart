import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:latlong2/latlong.dart';

import '../quest_test_support.dart';

const _player = LatLng(50.0, 19.0);

List<int> _ids(List<Quest> quests) => [for (final quest in quests) quest.id];

void main() {
  group('questBoardProvider', () {
    test('groups the available quests into places and routes', () async {
      final container = await createQuestContainer([
        testQuest(1, location: _player),
        testQuest(2, location: _player, isRoute: true),
        testQuest(3, location: _player, isStarted: true),
        testQuest(4, location: _player, isStarted: true, isCompleted: true),
      ], position: _player);

      final board = container.read(questBoardProvider);

      expect(_ids(board.places), [1]);
      expect(_ids(board.routes), [2]);
      expect(_ids(board.completed), [4]);
    });

    test('sorts the available quests from the nearest', () async {
      final container = await createQuestContainer([
        testQuest(1, location: const LatLng(50.005, 19.0)),
        testQuest(2, location: const LatLng(50.001, 19.0)),
        testQuest(3, location: const LatLng(50.003, 19.0)),
      ], position: _player);

      expect(_ids(container.read(questBoardProvider).places), [2, 3, 1]);
    });

    test('puts quests without a point last, in a stable order', () async {
      final container = await createQuestContainer([
        testQuest(5),
        testQuest(1, location: const LatLng(50.002, 19.0)),
        testQuest(4),
      ], position: _player);

      expect(_ids(container.read(questBoardProvider).places), [1, 4, 5]);
    });

    test('keeps the server order while the position is unknown', () async {
      final container = await createQuestContainer([
        testQuest(3, location: const LatLng(50.005, 19.0)),
        testQuest(1, location: const LatLng(50.001, 19.0)),
      ]);

      expect(_ids(container.read(questBoardProvider).places), [3, 1]);
    });

    test('lists the completed quests from the newest', () async {
      final container = await createQuestContainer([
        testQuest(
          1,
          isStarted: true,
          isCompleted: true,
          completedAt: DateTime(2026, 8, 24),
        ),
        testQuest(
          2,
          isStarted: true,
          isCompleted: true,
          completedAt: DateTime(2026, 9, 28),
        ),
        testQuest(3, isStarted: true, isCompleted: true),
      ]);

      expect(_ids(container.read(questBoardProvider).completed), [2, 1, 3]);
    });
  });
}
