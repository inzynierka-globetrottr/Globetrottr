import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/network/token_store.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';
import 'package:globetrottr_front/features/fog/provider/friend_fog_provider.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

class AuthNotifier extends Notifier<AuthState> {
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    Future.microtask(_checkExistingSession);
    return const AuthState();
  }

  /// A session check never logs out a user who got in while it was running
  /// (a login, or [enterWithoutLogin] while the backend is unreachable).
  Future<void> _checkExistingSession() async {
    try {
      final token = await _authService.refreshToken();
      state = state.copyWith(
        isAuthenticated: state.isAuthenticated || token != null,
        isInitializing: false,
      );
    } catch (e) {
      debugPrint('Session check did not authenticate: $e');
      final hasToken = await ref.read(tokenStoreProvider).getToken() != null;
      state = state.copyWith(
        isAuthenticated: state.isAuthenticated || hasToken,
        isInitializing: false,
      );
    }
  }

  /// Developer shortcut: uses the app without an account or a backend.
  /// Everything local works; calls to the backend fail as when offline.
  void enterWithoutLogin() {
    state = state.copyWith(
      isAuthenticated: true,
      isInitializing: false,
      isLoading: false,
      clearError: true,
    );
  }

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  Future<void> submit({
    required String username,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isAuthenticated: false,
      clearError: true,
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
      debugPrint('Unexpected error during auth submit: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      isAuthenticated: false,
      clearError: true,
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
      debugPrint('Unexpected error during Google sign-in: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<bool> logout({bool discardUnsyncedPoints = false}) async {
    final locationState = ref.read(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    if (locationState.isRecording) {
      await notifier.setRecording(false);
    }

    if (!discardUnsyncedPoints) {
      final hasPendingPoints =
          (await ref.read(mapStorageProvider).getPendingPoints()).isNotEmpty;
      if (hasPendingPoints) {
        final synced = await ref.read(syncServiceProvider).syncPendingPoints();
        if (!synced) return false;
      }
    }

    await ref.read(mapStorageProvider).clearPendingPoints();
    await _authService.logout();

    ref.invalidate(locationProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(friendsProvider);
    ref.invalidate(friendFogProvider);
    ref.invalidate(questsProvider);

    state = const AuthState(isInitializing: false);
    return true;
  }
}
