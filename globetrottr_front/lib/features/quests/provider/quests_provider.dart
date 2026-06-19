import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/quests/provider/quests_notifier.dart';
import 'package:globetrottr_front/features/quests/provider/quests_state.dart';

final questsProvider = NotifierProvider<QuestsNotifier, QuestsState>(() {
  return QuestsNotifier();
});
