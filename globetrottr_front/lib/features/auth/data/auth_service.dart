import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/core/network/token_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/features/auth/data/auth_response.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
import 'package:http/http.dart';

class AuthService {
  final ApiClient _client;
  final TokenStore _tokenStore;

  AuthService(this._client, this._tokenStore);

  Future<String> _extractAndSaveToken(Response response) async {
    final auth = AuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    if (auth.token.isNotEmpty) await _tokenStore.saveToken(auth.token);
    return auth.token;
  }

  Future<String?> signInWithGoogle() async {
    final String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: clientId);

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) throw const AuthException('Google authentication failed.');

    final response = await _client.post('/api/auth/google', body: {'token': idToken});
    final token = await _extractAndSaveToken(response);
    return token.isEmpty ? null : token;
  }

  Future<String> login(LoginRequest request) async {
    final response = await _client.post('/api/auth/login', body: request.toJson());
    return _extractAndSaveToken(response);
  }

  Future<String> register(RegisterRequest request) async {
    final response = await _client.post('/api/auth/register', body: request.toJson());
    return _extractAndSaveToken(response);
  }

  Future<String?> refreshToken() async {
    if (await _tokenStore.getToken() == null) return null;
    try {
      final response = await _client.get('/api/auth/refresh');
      final token = await _extractAndSaveToken(response);
      return token.isEmpty ? null : token;
    } on UnauthorizedException {
      await _tokenStore.deleteToken();
      rethrow;
    } on ForbiddenException {
      await _tokenStore.deleteToken();
      rethrow;
    }
  }

  Future<void> logout() => _tokenStore.deleteToken();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider), ref.read(tokenStoreProvider)),
);
