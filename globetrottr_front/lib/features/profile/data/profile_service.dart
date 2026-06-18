import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/profile/data/user_profile_response.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final AuthService _authService;

  ProfileService(this._authService);

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

  Future<UserProfileResponse> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/profile/me'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return UserProfileResponse.fromJson(jsonDecode(response.body));
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<void> updateBio(String bio) async {
    final response = await http.patch(
      Uri.parse('$_backendUrl/api/profile/bio'),
      headers: await _authHeaders(),
      body: jsonEncode({'bio': bio}),
    );

    if (response.statusCode == 200) return;

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<String> uploadAvatar(String filePath) async {
    final url = Uri.parse('$_backendUrl/api/profile/avatar');
    final request = http.MultipartRequest('POST', url);

    final headers = await _authHeaders();

    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final extension = filePath.split('.').last.toLowerCase();
    final subtype = (extension == 'jpg') ? 'jpeg' : extension;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: http.MediaType('image', subtype),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['avatarUrl'] as String;
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }
}

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(ref.read(authServiceProvider)),
);
