import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/network/token_store.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _http;
  final String _baseUrl;
  final Future<String?> Function() _tokenProvider;

  ApiClient({
    required http.Client http,
    required String baseUrl,
    required Future<String?> Function() tokenProvider,
  })  : _http = http,
        _baseUrl = baseUrl,
        _tokenProvider = tokenProvider;

  Uri uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, String>> _headers() async {
    final token = await _tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _guard() {
    if (_baseUrl.isEmpty) throw AppException('Backend URL is not configured.');
  }

  Never _throw(http.Response response) {
    String message;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      message = data['error'] as String? ?? 'Server error (${response.statusCode})';
    } catch (_) {
      message = 'Unexpected server error (${response.statusCode})';
    }
    throw AppException(message, response.statusCode);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    _guard();
    final resolvedUri = queryParameters != null
        ? uri(path).replace(queryParameters: queryParameters)
        : uri(path);
    final response = await _http.get(resolvedUri, headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    _guard();
    final response = await _http.post(
      uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    _guard();
    final response = await _http.patch(
      uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }

  Future<http.Response> delete(String path) async {
    _guard();
    final response = await _http.delete(uri(path), headers: await _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }

  Future<http.Response> sendMultipart(http.MultipartRequest request) async {
    _guard();
    final token = await _tokenProvider();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    http: http.Client(),
    baseUrl: dotenv.env['BACKEND_URL'] ?? '',
    tokenProvider: () => ref.read(tokenStoreProvider).getToken(),
  ),
);
