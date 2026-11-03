import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

class _FakeQuestService implements QuestService {
  int fetches = 0;

  @override
  Future<List<Quest>> fetchUserQuests() async {
    fetches++;
    return [
      const Quest(
        id: 1,
        title: 'Old Town',
        type: 'VISIT_POINTS',
        rewardPoints: 100,
        progress: 0,
        isStarted: true,
        isCompleted: false,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('the map loads the quests only the first time', () async {
    final service = _FakeQuestService();
    final container = ProviderContainer(
      overrides: [questServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(questsProvider.notifier);

    await notifier.loadQuestsOnce();
    await notifier.loadQuestsOnce();

    expect(service.fetches, 1);
    expect(container.read(questsProvider).quests, hasLength(1));
  });
}
