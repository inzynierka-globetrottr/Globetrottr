import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';

class SelectedQuestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(Quest quest) => state = quest.id;

  void clear() => state = null;
}

final selectedQuestIdProvider = NotifierProvider<SelectedQuestNotifier, int?>(
  SelectedQuestNotifier.new,
);
