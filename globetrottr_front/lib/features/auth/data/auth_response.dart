class AuthResponse {
  final String token;

  const AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(token: (json['token'] as String?) ?? '');
  }
}
