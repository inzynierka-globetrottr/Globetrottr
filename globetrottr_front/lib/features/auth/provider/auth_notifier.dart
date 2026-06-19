import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    Future.microtask(_checkExistingSession);
    return const AuthState();
  }

  Future<void> _checkExistingSession() async {
    try {
      final token = await _authService.refreshToken();
      state = state.copyWith(isAuthenticated: token != null, isInitializing: false);
    } catch (_) {
      state = state.copyWith(isAuthenticated: false, isInitializing: false);
    }
  }

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> submit({
    required String username,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isAuthenticated: false,
    );

    try {
      if (state.mode == AuthMode.login) {
        await _authService.login(
          LoginRequest(login: username, password: password),
        );
      } else {
        if (email == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Email is required',
          );
          return;
        }
        await _authService.register(
          RegisterRequest(username: username, email: email, password: password),
        );
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      isAuthenticated: false,
    );

    try {
      final token = await _authService.signInWithGoogle();

      if (token != null) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    final locationState = ref.read(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    if (locationState.isRecording) {
      await notifier.setRecording(false);
    }

    await ref.read(mapStorageProvider).clearPendingPoints();
    await _authService.logout();

    ref.invalidate(locationProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(friendsProvider);

    state = const AuthState(isInitializing: false);
  }
}
