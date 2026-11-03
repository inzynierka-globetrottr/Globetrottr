import 'package:globetrottr_front/features/quests/data/quest.dart';

class QuestsState {
  final List<Quest> quests;
  final bool isLoading;
  final String? errorMessage;

  /// The list has come from the backend at least once.
  final bool hasLoaded;

  const QuestsState({
    this.quests = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false,
  });

  QuestsState copyWith({
    List<Quest>? quests,
    bool? isLoading,
    String? errorMessage,
    bool? hasLoaded,
    bool clearError = false,
  }) => QuestsState(
    quests: quests ?? this.quests,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    hasLoaded: hasLoaded ?? this.hasLoaded,
  );
}
