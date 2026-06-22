import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class FriendsService {
  final ApiClient _client;

  FriendsService(this._client);

  Future<List<FriendshipResponse>> _getList(String path) async {
    final response = await _client.get(path);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => FriendshipResponse.fromJson(json)).toList();
  }

  Future<List<FriendshipResponse>> getFriends() => _getList('/api/friends');

  Future<List<FriendshipResponse>> getReceivedInvites() =>
      _getList('/api/friends/invites');

  Future<List<FriendshipResponse>> getSentInvites() =>
      _getList('/api/friends/invites/sent');

  // TODO: change _getList to take in parameters, so this function could be simplified too
  Future<List<FriendshipResponse>> searchUsers(String query) async {
    final response = await _client.get(
      '/api/friends/search',
      queryParameters: {'query': query},
    );
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => FriendshipResponse.fromJson(json)).toList();
  }

  Future<void> sendInvite(String username) =>
    _client.post('/api/friends/invites', body: {'username': username});

  Future<void> acceptInvite(String username) =>
      _client.post('/api/friends/invites/$username/accept');

  Future<void> deleteRelationship(String username) =>
      _client.delete('/api/friends/$username');
}

final friendsServiceProvider = Provider<FriendsService>(
  (ref) => FriendsService(ref.read(apiClientProvider)),
);
