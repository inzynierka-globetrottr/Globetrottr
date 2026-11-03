import 'package:flutter/foundation.dart';
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quests = await _service.fetchUserQuests();
      state = state.copyWith(
        isLoading: false,
        quests: quests,
        hasLoaded: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('Unexpected error loading quests: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Failed to load quests.',
      );
    }
  }

  /// For screens that only need some list, such as the map; the Quests tab
  /// refreshes it with [loadQuests] on every visit.
  Future<void> loadQuestsOnce() async {
    if (state.hasLoaded || state.isLoading) return;
    await loadQuests();
  }

  Future<void> startQuest(int questId) async {
    try {
      await _service.startQuest(questId);
      await loadQuests();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error starting quest: $e');
      throw const UnknownException();
    }
  }
}
