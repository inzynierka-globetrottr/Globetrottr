import 'package:globetrottr_front/features/quests/data/quest.dart';

class QuestsState {
  final List<Quest> quests;
  final bool isLoading;
  final String? errorMessage;

  /// The list has come from the backend at least once.
  final bool hasLoaded;

  /// A start is on the way; until the list is reloaded the old quest is
  /// still the active one, so no other start can be offered.
  final bool isStarting;

  const QuestsState({
    this.quests = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false,
    this.isStarting = false,
  });

  QuestsState copyWith({
    List<Quest>? quests,
    bool? isLoading,
    String? errorMessage,
    bool? hasLoaded,
    bool? isStarting,
    bool clearError = false,
  }) => QuestsState(
    quests: quests ?? this.quests,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    hasLoaded: hasLoaded ?? this.hasLoaded,
    isStarting: isStarting ?? this.isStarting,
  );
}
