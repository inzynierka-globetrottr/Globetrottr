import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

/// One quest is active at a time: the first one started and not completed.
Quest? activeQuest(List<Quest> quests) {
  for (final quest in quests) {
    if (quest.isStarted && !quest.isCompleted) return quest;
  }
  return null;
}

final activeQuestProvider = Provider<Quest?>(
  (ref) => activeQuest(ref.watch(questsProvider.select((s) => s.quests))),
);
