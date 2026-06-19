import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/core/network/token_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';

class AuthService {
  final ApiClient _client;
  final TokenStore _tokenStore;

  AuthService(this._client, this._tokenStore);

  Future<String?> signInWithGoogle() async {
    final String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: clientId);

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) throw AppException('Google authentication failed.');

    final response = await _client.post('/api/auth/google', body: {'token': idToken});
    final token = (jsonDecode(response.body) as Map<String, dynamic>)['token'];
    await _tokenStore.saveToken(token);
    return token;
  }

  Future<String> login(LoginRequest request) async {
    final response = await _client.post('/api/auth/login', body: request.toJson());
    final token = (jsonDecode(response.body) as Map<String, dynamic>)['token'];
    await _tokenStore.saveToken(token);
    return token;
  }

  Future<String> register(RegisterRequest request) async {
    final response = await _client.post('/api/auth/register', body: request.toJson());
    final token = (jsonDecode(response.body) as Map<String, dynamic>)['token'] ?? '';
    if (token.toString().isNotEmpty) await _tokenStore.saveToken(token);
    return token;
  }

  Future<String?> refreshToken() async {
    if (await _tokenStore.getToken() == null) return null;
    try {
      final response = await _client.get('/api/auth/refresh');
      final newToken = (jsonDecode(response.body) as Map<String, dynamic>)['token'];
      await _tokenStore.saveToken(newToken);
      return newToken;
    } on AppException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokenStore.deleteToken();
        throw AppException('Session expired. Please log in again.', e.statusCode);
      }
      throw AppException('Server temporarily unavailable.', e.statusCode);
    }
  }

  Future<void> logout() => _tokenStore.deleteToken();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider), ref.read(tokenStoreProvider)),
);
