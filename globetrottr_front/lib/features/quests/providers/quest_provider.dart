import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/quests/services/quest_service.dart';
import 'package:globetrottr_front/features/quests/models/quest.dart';

final questServiceProvider = Provider<QuestService>(
  (ref) => QuestService(ref.read(apiClientProvider)),
);

final userQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  return ref.read(questServiceProvider).fetchUserQuests();
});
