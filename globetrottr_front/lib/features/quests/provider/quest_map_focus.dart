import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A request from the Quests tab to show the active quest on the map. The
/// map answers it once and clears it.
class QuestMapFocus extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  void clear() => state = false;
}

final questMapFocusProvider = NotifierProvider<QuestMapFocus, bool>(
  QuestMapFocus.new,
);
