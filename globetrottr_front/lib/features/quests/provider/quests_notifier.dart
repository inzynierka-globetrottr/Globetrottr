import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quests_state.dart';

class QuestsNotifier extends Notifier<QuestsState> {
  late QuestService _service;

  @override
  QuestsState build() {
    _service = ref.read(questServiceProvider);
    return const QuestsState();
  }

  Future<void> loadQuests() async {
    state = state.copyWith(isLoading: true);
    try {
      final quests = await _service.fetchUserQuests();
      state = state.copyWith(isLoading: false, quests: quests);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      print('Unexpected error loading quests: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Failed to load quests.');
    }
  }

  Future<void> startQuest(int questId) async {
    try {
      await _service.startQuest(questId);
      await loadQuests();
    } on AppException {
      rethrow;
    } catch (e) {
      print('Unexpected error starting quest: $e');
      throw const UnknownException();
    }
  }
}
