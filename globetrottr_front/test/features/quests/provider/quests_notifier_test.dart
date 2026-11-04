import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

import '../quest_test_support.dart';

void main() {
  test('a quest is started once however often it is tapped', () async {
    final service = FakeQuestService([testQuest(1), testQuest(2)]);
    final container = await createQuestContainer(
      service.quests,
      service: service,
    );
    final notifier = container.read(questsProvider.notifier);

    final first = notifier.startQuest(1);
    await notifier.startQuest(1);
    // Only one quest can be active, so another start waits for this one.
    await notifier.startQuest(2);
    await first;

    expect(service.started, [1]);

    await notifier.startQuest(2);
    expect(service.started, [1, 2]);
  });
}
