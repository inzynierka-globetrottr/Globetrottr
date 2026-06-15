import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class FriendsState {
  final List<FriendshipResponse> friends;
  final List<FriendshipResponse> receivedInvites;
  final List<FriendshipResponse> sentInvites;
  final List<FriendshipResponse> searchResults;
  final bool isLoading;
  final String? errorMessage;

  const FriendsState({
    this.friends = const [],
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    List<FriendshipResponse>? friends,
    List<FriendshipResponse>? receivedInvites,
    List<FriendshipResponse>? sentInvites,
    List<FriendshipResponse>? searchResults,
    bool? isLoading,
    String? errorMessage,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        receivedInvites: receivedInvites ?? this.receivedInvites,
        sentInvites: sentInvites ?? this.sentInvites,
        searchResults: searchResults ?? this.searchResults,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}