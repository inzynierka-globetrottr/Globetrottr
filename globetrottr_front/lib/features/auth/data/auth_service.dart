import 'dart:convert';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';

class AuthService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  String _parseError(String responseBody, int statusCode) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['error'] ?? 'Server error ($statusCode)';
    } catch (_) {
      return 'Unexpected server error ($statusCode)';
    }
  }

  Future<String?> signInWithGoogle() async {
    if (_backendUrl.isEmpty)
      throw AppException('Backend URL is not configured.');

    final String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: clientId);

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) throw AppException('Google authentication failed.');

    final response = await http.post(
      Uri.parse('$_backendUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'];

      await _storage.write(key: _tokenKey, value: token);

      return token;
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<String> login(LoginRequest request) async {
    if (_backendUrl.isEmpty)
      throw AppException('Backend URL is not configured.');

    final response = await http.post(
      Uri.parse('$_backendUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'];
      await _storage.write(key: _tokenKey, value: token);

      return token;
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<String> register(RegisterRequest request) async {
    if (_backendUrl.isEmpty)
      throw AppException('Backend URL is not configured.');

    final response = await http.post(
      Uri.parse('$_backendUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'];

      if (token != null && token.toString().isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }

      return token ?? '';
    }

    throw AppException(
      _parseError(response.body, response.statusCode),
      response.statusCode,
    );
  }

  Future<String?> refreshToken() async {
    final currentToken = await getToken();

    if (currentToken == null || _backendUrl.isEmpty) return null;

    final response = await http.get(
      Uri.parse('$_backendUrl/api/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $currentToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newToken = data['token'];
      await _storage.write(key: _tokenKey, value: newToken);
      return newToken;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await deleteToken();
      throw AppException(
        'Session expired. Please log in again.',
        response.statusCode,
      );
    } else {
      throw AppException(
        'Server temporarily unavailable.',
        response.statusCode,
      );
    }
  }

  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt_token');
  }
}
