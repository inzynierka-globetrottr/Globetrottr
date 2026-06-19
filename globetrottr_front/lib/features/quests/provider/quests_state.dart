import 'package:globetrottr_front/features/quests/data/quest.dart';

class QuestsState {
  final List<Quest> quests;
  final bool isLoading;
  final String? errorMessage;

  const QuestsState({
    this.quests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  QuestsState copyWith({
    List<Quest>? quests,
    bool? isLoading,
    String? errorMessage,
  }) => QuestsState(
    quests: quests ?? this.quests,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
