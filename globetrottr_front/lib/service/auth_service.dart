import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';

class AuthService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    return await _storage.delete(key: _tokenKey);
  }

  Future<String?> login(LoginRequest request) async {
    if (_backendUrl.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: _tokenKey, value: token);
        return token;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> register(RegisterRequest request) async {
    if (_backendUrl.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: _tokenKey, value: token);
        return token;
      }

      return null;

    } catch (e) {
      return null;
    }
  }

  Future<String?> refreshToken() async {
    final currentToken = await getToken();

    if (currentToken == null || _backendUrl.isEmpty ) return null;

    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        await _storage.write(key: _tokenKey, value: newToken);
        return newToken;
      } else {
        deleteToken();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

}
