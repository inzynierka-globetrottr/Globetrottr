import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, errorMessage: null);
  }

  Future<void> submit({
    required String username,
    required String password,
    String? email,
    required VoidCallback onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    String? token;

    if (state.mode == AuthMode.login) {
      token = await _authService.login(
        LoginRequest(login: username, password: password),
      );
    } else {
      token = await _authService.register(
        RegisterRequest(username: username, email: email!, password: password),
      );
    }

    if (token != null) {
      state = state.copyWith(isLoading: false);
      onSuccess();
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.mode == AuthMode.login
            ? 'Sign in didn\'t work'
            : 'Sign up didn\'t work',
      );
    }
  }

  Future<void> signInWithGoogle({required VoidCallback onSuccess}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final token = await _authService.signInWithGoogle();
    if (token != null) {
      onSuccess();
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in with google didn\'t work',
      );
    }
  }
}