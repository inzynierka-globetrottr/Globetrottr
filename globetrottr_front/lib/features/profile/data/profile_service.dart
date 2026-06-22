import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/profile/data/user_profile_response.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final ApiClient _client;

  ProfileService(this._client);

  Future<UserProfileResponse> getMyProfile() async {
    final response = await _client.get('/api/profile/me');
    return UserProfileResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> updateBio(String bio) =>
      _client.patch('/api/profile/bio', body: {'bio': bio});

  Future<String> uploadAvatar(String filePath) async {
    final request = http.MultipartRequest('POST', _client.uri('/api/profile/avatar'));

    final extension = filePath.split('.').last.toLowerCase();
    final subtype = extension == 'jpg' ? 'jpeg' : extension;

    request.files.add(await http.MultipartFile.fromPath(
      'file', filePath,
      contentType: http.MediaType('image', subtype),
    ));

    final response = await _client.sendMultipart(request);
    return (jsonDecode(response.body) as Map<String, dynamic>)['avatarUrl'] as String;
  }
}

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(ref.read(apiClientProvider)),
);
