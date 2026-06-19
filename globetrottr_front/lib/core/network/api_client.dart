import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    if (_baseUrl.isEmpty) throw const ConfigurationException('Backend URL is not configured.');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request();
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on HttpException catch (e) {
      throw NetworkException(e.message);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
 
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    _throw(response);
  }

  Never _throw(http.Response response) {
    String? serverMessage;

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      serverMessage = data['error'] as String?;
    } catch (_) {
      serverMessage = null;
    }
 
    final statusCode = response.statusCode;
    final message = serverMessage ?? 'Server error ($statusCode)';
 
    switch (statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 400:
      case 422:
        throw ValidationException(message, statusCode);
      default:
        throw ServerException(message, statusCode);
    }
  }


  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    _guard();
    final resolvedUri = queryParameters != null
        ? uri(path).replace(queryParameters: queryParameters)
        : uri(path);
    final headers = await _headers();
    return _send(() => _http.get(resolvedUri, headers: headers));
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    _guard();
    final headers = await _headers();
    return _send(() => _http.post(
          uri(path),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ));
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    _guard();
    final headers = await _headers();
    return _send(() => _http.patch(
          uri(path),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ));
  }

  Future<http.Response> delete(String path) async {
    _guard();
    final headers = await _headers();
    return _send(() => _http.delete(uri(path), headers: headers));
  }


  Future<http.Response> sendMultipart(http.MultipartRequest request) async {
    _guard();
    final token = await _tokenProvider();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    return _send(() async {
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    });
  }

}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    http: http.Client(),
    baseUrl: dotenv.env['BACKEND_URL'] ?? '',
    tokenProvider: () => ref.read(tokenStoreProvider).getToken(),
  ),
);
