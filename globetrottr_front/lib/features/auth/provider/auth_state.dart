/// The auth screen whose action failed. The screens share one state, so
/// each shows only its own error.
enum AuthForm { login, register, verify }

class AuthState {
  final bool isLoading;
  final String? errorMessage;

  /// Where [errorMessage] came from.
  final AuthForm? errorForm;
  final bool isAuthenticated;

  /// Uses the app without an account; everything local works.
  final bool isGuest;
  final bool isInitializing;

  /// Address of a new account waiting for its e-mail code.
  final String? pendingVerificationEmail;

  /// When another verification code may be requested.
  final DateTime? resendAvailableAt;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.errorForm,
    this.isAuthenticated = false,
    this.isGuest = false,
    this.isInitializing = true,
    this.pendingVerificationEmail,
    this.resendAvailableAt,
  });

  bool get canEnterApp => isAuthenticated || isGuest;

  String? errorFor(AuthForm form) => errorForm == form ? errorMessage : null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthForm? errorForm,
    bool? isAuthenticated,
    bool? isGuest,
    bool? isInitializing,
    String? pendingVerificationEmail,
    DateTime? resendAvailableAt,
    bool clearError = false,
    bool clearVerification = false,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    errorForm: clearError ? null : (errorForm ?? this.errorForm),
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    isGuest: isGuest ?? this.isGuest,
    isInitializing: isInitializing ?? this.isInitializing,
    pendingVerificationEmail: clearVerification
        ? null
        : (pendingVerificationEmail ?? this.pendingVerificationEmail),
    resendAvailableAt: clearVerification
        ? null
        : (resendAvailableAt ?? this.resendAvailableAt),
  );
}
