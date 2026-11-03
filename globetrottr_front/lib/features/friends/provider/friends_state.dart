import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class FriendsState {
  final List<FriendshipResponse> friends;
  final List<FriendshipResponse> receivedInvites;
  final List<FriendshipResponse> sentInvites;
  final bool isLoading;

  /// Whether the lists were asked for at least once, so empty lists mean
  /// there is nothing rather than that nothing has come yet.
  final bool hasLoaded;
  final String? errorMessage;

  const FriendsState({
    this.friends = const [],
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    List<FriendshipResponse>? friends,
    List<FriendshipResponse>? receivedInvites,
    List<FriendshipResponse>? sentInvites,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) => FriendsState(
    friends: friends ?? this.friends,
    receivedInvites: receivedInvites ?? this.receivedInvites,
    sentInvites: sentInvites ?? this.sentInvites,
    isLoading: isLoading ?? this.isLoading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
