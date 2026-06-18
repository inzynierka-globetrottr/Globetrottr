import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';

class AuthState {
  final AuthMode mode;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.mode = AuthMode.login,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AuthMode? mode,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) => AuthState(
    mode: mode ?? this.mode,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage ?? this.errorMessage,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
  );
}
