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

  Future<Map<String, String?>> _fetchAvatars(Iterable<String> usernames) async {
    final entries = await Future.wait(usernames.map((username) async {
      try {
        final avatarUrl = await _profileService.getAvatarUrl(username);
        return MapEntry(username, avatarUrl);
      } catch (e) {
        return MapEntry(username, null);
      }
    }));
    return Map.fromEntries(entries);
  }

  List<FriendshipResponse> _withAvatars(
    List<FriendshipResponse> list,
    Map<String, String?> avatars,
  ) {
    return list.map((r) => r.copyWith(avatarUrl: avatars[r.username])).toList();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);

    try {
      final results = await Future.wait([
        _service.getFriends(),
        _service.getReceivedInvites(),
        _service.getSentInvites(),
      ]);

      final friends = results[0];
      final receivedInvites = results[1];
      final sentInvites = results[2];

      final usernames = {
        ...friends.map((f) => f.username),
        ...receivedInvites.map((f) => f.username),
        ...sentInvites.map((f) => f.username),
      };
      final avatars = await _fetchAvatars(usernames);

      state = state.copyWith(
        isLoading: false,
        friends: _withAvatars(friends, avatars),
        receivedInvites: _withAvatars(receivedInvites, avatars),
        sentInvites: _withAvatars(sentInvites, avatars),
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      print('Unexpected error loading friends: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong.');
    }
  }

  Future<void> sendInvite(String username) async {
    try {
      await _service.sendInvite(username);
      state = state.copyWith(
        sentInvites: [
          ...state.sentInvites,
          FriendshipResponse(
            username: username,
            status: InviteStatus.pending,
            isIncomingRequest: false,
          ),
        ],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      print('Unexpected error sending invite: $e');
      throw const UnknownException();
    }
  }

  Future<void> acceptInvite(String username) async {
    try {
      await _service.acceptInvite(username);

      state = state.copyWith(
        receivedInvites: state.receivedInvites
            .where((r) => r.username != username)
            .toList(),
        friends: [
          ...state.friends,
          FriendshipResponse(
            username: username,
            status: InviteStatus.accepted,
            isIncomingRequest: false,
          ),
        ],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      print('Unexpected error accepting invite: $e');
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
      print('Unexpected error deleting relationship: $e');
      throw const UnknownException();
    }
  }
}
