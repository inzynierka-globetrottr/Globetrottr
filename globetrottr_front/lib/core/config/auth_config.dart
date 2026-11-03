class AuthConfig {
  AuthConfig._();

  /// Digits of an e-mail verification code.
  static const int codeLength = 6;

  /// How long the backend accepts a verification code.
  static const Duration codeValidity = Duration(minutes: 15);

  /// Shortest wait before another code can be sent.
  static const Duration resendCooldown = Duration(seconds: 60);
}
