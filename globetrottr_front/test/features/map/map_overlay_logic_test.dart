import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';

Quest _quest(int id, {bool started = false, bool completed = false}) => Quest(
  id: id,
  title: 'Quest $id',
  type: 'DISCOVER',
  rewardPoints: 10,
  progress: 0.6,
  isStarted: started,
  isCompleted: completed,
);

void main() {
  group('active quest', () {
    test('is the first started quest that is not completed', () {
      final quests = [
        _quest(1),
        _quest(2, started: true, completed: true),
        _quest(3, started: true),
        _quest(4, started: true),
      ];

      expect(activeQuest(quests)?.id, 3);
    });

    test('is none when nothing is in progress', () {
      expect(
        activeQuest([_quest(1), _quest(2, started: true, completed: true)]),
        isNull,
      );
    });
  });

  group('map view', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('starts on the fog', () {
      expect(container.read(mapViewProvider), MapView.fog);
    });

    test('only the fog can be chosen until the other views exist', () {
      final notifier = container.read(mapViewProvider.notifier);

      expect(notifier.select(MapView.heatmap), isFalse);
      expect(container.read(mapViewProvider), MapView.fog);
      expect(notifier.select(MapView.fog), isTrue);
    });
  });
}
