import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:http/http.dart' as http;

class FriendsService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final AuthService _authService;
  FriendsService(this._authService); 

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _parseError(String responseBody, int statusCode) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['error'] ?? 'Server error ($statusCode)';
    } catch (_) {
      return 'Unexpected server error ($statusCode)';
    }
  }

  Future<List<FriendshipResponse>> _getList(String path) async {
    final response = await http.get(
      Uri.parse('$_backendUrl$path'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FriendshipResponse.fromJson(json)).toList();
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<List<FriendshipResponse>> getFriends() => _getList('/api/friends');

  Future<List<FriendshipResponse>> getReceivedInvites() =>
      _getList('/api/friends/invites');

  Future<List<FriendshipResponse>> getSentInvites() =>
      _getList('/api/friends/invites/sent');

  // TODO: change _getList to take in parameters, so this function could be simplified too
  Future<List<FriendshipResponse>> searchUsers(String query) async {
    final uri = Uri.parse(
      '$_backendUrl/api/friends/search',
    ).replace(queryParameters: {'query': query});

    final response = await http.get(uri, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FriendshipResponse.fromJson(json)).toList();
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<void> sendInvite(String username) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/friends/invites'),
      headers: await _authHeaders(),
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) return;

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<void> acceptInvite(String username) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/friends/invites/$username/accept'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) return;

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<void> deleteRelationship(String username) async {
    final response = await http.delete(
      Uri.parse('$_backendUrl/api/friends/$username'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) return;

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }
}

final friendsServiceProvider = Provider<FriendsService>(
  (ref) => FriendsService(ref.read(authServiceProvider)),
);
