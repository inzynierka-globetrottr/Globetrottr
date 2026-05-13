import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';

class AuthService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<String?> signInWithGoogle() async {
    if (_backendUrl.isEmpty) return null;

    try {
      final String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];

      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: clientId);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
      return null;
    } catch (e) {
      return null;
    }
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
        return data['token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    if (_backendUrl.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
