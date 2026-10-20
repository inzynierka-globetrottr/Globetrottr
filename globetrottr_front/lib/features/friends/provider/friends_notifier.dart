import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/data/invite_status.dart';
import 'package:globetrottr_front/features/friends/provider/friends_state.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';

class FriendsNotifier extends Notifier<FriendsState> {
  late FriendsService _service;
  late ProfileService _profileService;

  @override
  FriendsState build() {
    _service = ref.read(friendsServiceProvider);
    _profileService = ref.read(profileServiceProvider);
    return const FriendsState();
  }

  // TODO: N + 1 problem, make an endpoint for this in the backend
  Future<Map<String, String?>> _fetchAvatars(Iterable<String> usernames) async {
    final entries = await Future.wait(
      usernames.map((username) async {
        try {
          final avatarUrl = await _profileService.getAvatarUrl(username);
          return MapEntry(username, avatarUrl);
        } catch (e) {
          return MapEntry(username, null);
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  List<FriendshipResponse> _withAvatars(
    List<FriendshipResponse> list,
    Map<String, String?> avatars,
  ) {
    return list.map((r) => r.copyWith(avatarUrl: avatars[r.username])).toList();
  }

  Future<void> _loadAvatars({
    required Iterable<String> friends,
    required Iterable<String> received,
    required Iterable<String> sent,
  }) async {
    final allUsernames = {
      ...friends,
      ...received,
      ...sent,
    };
    final avatars = await _fetchAvatars(allUsernames);
    state = state.copyWith(
      friends: _withAvatars(state.friends, avatars),
      receivedInvites: _withAvatars(state.receivedInvites, avatars),
      sentInvites: _withAvatars(state.sentInvites, avatars),
    );
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _service.getFriends(),
        _service.getReceivedInvites(),
        _service.getSentInvites(),
      ]);

      state = state.copyWith(
        isLoading: false,
        friends: results[0],
        receivedInvites: results[1],
        sentInvites: results[2],
      );

      await _loadAvatars(
        friends: results[0].map((f) => f.username),
        received: results[1].map((f) => f.username),
        sent: results[2].map((f) => f.username),
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('Unexpected error loading friends: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong.',
      );
    }
  }

  Future<void> sendInvite(String username) async {
    try {
      await _service.sendInvite(username);
      final newInvite = FriendshipResponse(
        username: username,
        status: InviteStatus.pending,
        isIncomingRequest: false,
      );
      state = state.copyWith(
        sentInvites: [...state.sentInvites, newInvite],
      );
      final avatars = await _fetchAvatars([username]);
      state = state.copyWith(
        sentInvites: _withAvatars(state.sentInvites, avatars),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error sending invite: $e');
      throw const UnknownException();
    }
  }

  Future<void> acceptInvite(String username) async {
    try {
      await _service.acceptInvite(username);

      final invite = state.receivedInvites
          .where((r) => r.username == username)
          .firstOrNull;
      final friend =
          invite?.copyWith(
            status: InviteStatus.accepted,
            isIncomingRequest: false,
          ) ??
          FriendshipResponse(
            username: username,
            status: InviteStatus.accepted,
            isIncomingRequest: false,
          );

      state = state.copyWith(
        receivedInvites: state.receivedInvites
            .where((r) => r.username != username)
            .toList(),
        friends: [...state.friends, friend],
      );

      if (friend.avatarUrl == null) {
        final avatars = await _fetchAvatars([username]);
        state = state.copyWith(friends: _withAvatars(state.friends, avatars));
      }
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error accepting invite: $e');
      throw const UnknownException();
    }
  }

  Future<void> deleteRelationship(String username) async {
    try {
      await _service.deleteRelationship(username);

      state = state.copyWith(
        friends: state.friends.where((r) => r.username != username).toList(),
        receivedInvites: state.receivedInvites
            .where((r) => r.username != username)
            .toList(),
        sentInvites: state.sentInvites
            .where((r) => r.username != username)
            .toList(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error deleting relationship: $e');
      throw const UnknownException();
    }
  }
}
