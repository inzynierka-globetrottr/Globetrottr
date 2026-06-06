import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/data/invite_status.dart';
import 'package:globetrottr_front/features/friends/provider/friends_state.dart';

class FriendsNotifier extends Notifier<FriendsState> {
  late final FriendsService _service;

  @override
  FriendsState build() {
    _service = FriendsService();
    return const FriendsState();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please check your connection.',
      );
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
      throw AppException('Network error. Please check your connection.');
    }
  }

  Future<void> acceptInvite(String username) async {
    try {
      await _service.acceptInvite(username);

      final accepted = state.receivedInvites
          .firstWhere((r) => r.username == username);

      state = state.copyWith(
        receivedInvites: state.receivedInvites
            .where((r) => r.username != username)
            .toList(),
        friends: [
          ...state.friends,
          FriendshipResponse(
            username: accepted.username,
            status: InviteStatus.accepted,
            isIncomingRequest: false,
          ),
        ],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Network error. Please check your connection.');
    }
  }

  Future<void> deleteRelationship(String username) async {
    try {
      await _service.deleteRelationship(username);

      state = state.copyWith(
        friends: state.friends
            .where((r) => r.username != username)
            .toList(),
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
      throw AppException('Network error. Please check your connection.');
    }
  }
}