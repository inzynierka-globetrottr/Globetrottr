import 'dart:convert';

String parseApiError(String responseBody, int statusCode) {
  try {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['error'] ?? 'Server error ($statusCode)';
  } catch (_) {
    return 'Unexpected server error ($statusCode)';
  }
}
