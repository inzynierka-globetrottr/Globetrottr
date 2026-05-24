import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService();
    return const AuthState();
  }

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, errorMessage: null);
  }

  Future<void> submit({
    required String username,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isAuthenticated: false);
    String? token;

    if (state.mode == AuthMode.login) {
      token = await _authService.login(
        LoginRequest(login: username, password: password),
      );
    } else {
      if (email == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Email is required');
        return;
      }
      token = await _authService.register(
        RegisterRequest(username: username, email: email, password: password),
      );
    }

    if (token != null) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: state.mode == AuthMode.login
            ? 'Sign in didn\'t work'
            : 'Sign up didn\'t work',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isAuthenticated: false);
    final token = await _authService.signInWithGoogle();
    if (token != null) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Sign in with Google didn\'t work',
      );
    }
  }
}