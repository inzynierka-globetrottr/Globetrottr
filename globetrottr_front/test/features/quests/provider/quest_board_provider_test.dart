import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/location_notifier.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationNotifier extends LocationNotifier {
  _FakeLocationNotifier(this._initial);

  final LatLng? _initial;

  @override
  TrackingState build() => TrackingState(currentPosition: _initial);

  void moveTo(LatLng position) =>
      state = state.copyWith(currentPosition: position);
}

class _FakeQuestService extends Fake implements QuestService {
  _FakeQuestService(this.quests);

  final List<Quest> quests;

  @override
  Future<List<Quest>> fetchUserQuests() async => quests;
}

Quest _quest(
  int id, {
  LatLng? location,
  bool isStarted = false,
  bool isCompleted = false,
}) => Quest(
  id: id,
  title: 'Quest $id',
  type: 'VISIT_POINTS',
  rewardPoints: 0,
  progress: 0,
  isStarted: isStarted,
  isCompleted: isCompleted,
  location: location,
);

const _player = LatLng(50.0, 19.0);

Future<ProviderContainer> _createContainer(
  List<Quest> quests, {
  LatLng? position = _player,
}) async {
  final container = ProviderContainer(
    overrides: [
      questServiceProvider.overrideWithValue(_FakeQuestService(quests)),
      locationProvider.overrideWith(() => _FakeLocationNotifier(position)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(questsProvider.notifier).loadQuests();
  return container;
}

List<int> _ids(List<QuestBoardEntry> entries) => [
  for (final entry in entries) entry.quest.id,
];

void main() {
  group('questBoardProvider', () {
    test('splits quests by zone', () async {
      final container = await _createContainer([
        _quest(1, location: _player),
        _quest(2, location: _player, isStarted: true),
        _quest(3, location: _player, isStarted: true, isCompleted: true),
      ]);

      final board = container.read(questBoardProvider);

      expect(_ids(board.unstarted), [1]);
      expect(_ids(board.inProgress), [2]);
      expect(_ids(board.completed), [3]);
    });

    test('sorts quests from the nearest and keeps their distance', () async {
      final container = await _createContainer([
        _quest(1, location: const LatLng(50.005, 19.0)),
        _quest(2, location: const LatLng(50.001, 19.0)),
        _quest(3, location: const LatLng(50.003, 19.0)),
      ]);

      final board = container.read(questBoardProvider);

      expect(_ids(board.unstarted), [2, 3, 1]);
      expect(board.unstarted.first.distanceMeters, closeTo(111, 1));
    });

    test('puts quests without a distance last, in a stable order', () async {
      final container = await _createContainer([
        _quest(5),
        _quest(1, location: const LatLng(50.002, 19.0)),
        _quest(4),
        _quest(2, location: const LatLng(50.002, 19.0)),
      ]);

      final board = container.read(questBoardProvider);

      expect(_ids(board.unstarted), [1, 2, 4, 5]);
      expect(board.unstarted.last.distanceMeters, isNull);
    });

    test('keeps the server order while the position is unknown', () async {
      final container = await _createContainer([
        _quest(3, location: const LatLng(50.005, 19.0)),
        _quest(1, location: const LatLng(50.001, 19.0)),
      ], position: null);

      final board = container.read(questBoardProvider);

      expect(_ids(board.unstarted), [3, 1]);
      expect(board.unstarted.every((e) => e.distanceMeters == null), isTrue);
    });

    test('sorts again when the player moves', () async {
      final container = await _createContainer([
        _quest(1, location: const LatLng(50.001, 19.0)),
        _quest(2, location: const LatLng(50.009, 19.0)),
      ]);
      expect(_ids(container.read(questBoardProvider).unstarted), [1, 2]);

      (container.read(locationProvider.notifier) as _FakeLocationNotifier)
          .moveTo(const LatLng(50.01, 19.0));

      expect(_ids(container.read(questBoardProvider).unstarted), [2, 1]);
    });
  });
}
