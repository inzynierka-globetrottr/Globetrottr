import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/network/token_store.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';
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

  DateTime get _now => ref.read(clockProvider)();

  /// A session check never logs out a user who got in while it was running
  /// (a login, or a guest while the backend is unreachable).
  Future<void> _checkExistingSession() async {
    if (await _storedGuest()) {
      state = state.copyWith(isGuest: true, isInitializing: false);
      return;
    }
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

  Future<bool> _storedGuest() async {
    try {
      return await _authService.isGuest();
    } catch (e) {
      debugPrint('Could not read the guest choice: $e');
      return false;
    }
  }

  /// Uses the app without an account, also after a restart. Everything local
  /// works; calls to the backend fail as when offline.
  Future<void> continueAsGuest() async {
    try {
      await _authService.startGuestSession();
    } catch (e) {
      debugPrint('Could not store the guest choice: $e');
    }
    state = state.copyWith(
      isGuest: true,
      isInitializing: false,
      isLoading: false,
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) state = state.copyWith(clearError: true);
  }

  Future<void> login({required String login, required String password}) =>
      _run(() async {
        await _authService.login(
          LoginRequest(login: login.trim(), password: password),
        );
        state = state.copyWith(isAuthenticated: true);
      });

  /// A new account is locked until its e-mail is verified with a code.
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) => _run(() async {
    await _authService.register(
      RegisterRequest(
        username: username.trim(),
        email: email.trim(),
        password: password,
      ),
    );
    state = state.copyWith(
      // The backend stores addresses in lower case.
      pendingVerificationEmail: email.trim().toLowerCase(),
      resendAvailableAt: _now.add(AuthConfig.resendCooldown),
    );
  });

  Future<void> verifyEmail(String code) async {
    final email = state.pendingVerificationEmail;
    if (email == null) return;
    await _run(() async {
      await _authService.verifyEmail(email: email, code: code);
      state = state.copyWith(isAuthenticated: true, clearVerification: true);
    });
  }

  /// Ignored until [AuthState.resendAvailableAt].
  Future<void> resendVerificationCode() async {
    final email = state.pendingVerificationEmail;
    final availableAt = state.resendAvailableAt;
    if (email == null) return;
    if (availableAt != null && _now.isBefore(availableAt)) return;
    await _run(() async {
      await _authService.resendVerificationCode(email);
      state = state.copyWith(
        resendAvailableAt: _now.add(AuthConfig.resendCooldown),
      );
    });
  }

  Future<void> signInWithGoogle() => _run(() async {
    final token = await _authService.signInWithGoogle();
    if (token != null) state = state.copyWith(isAuthenticated: true);
  });

  /// Shows progress while [action] runs and turns its failure into an error
  /// message.
  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// A guest has nothing to sync; a signed-in user's pending points are sent
  /// first unless [discardUnsyncedPoints].
  Future<bool> logout({bool discardUnsyncedPoints = false}) async {
    final locationState = ref.read(locationProvider);
    final notifier = ref.read(locationProvider.notifier);

    if (locationState.isRecording) {
      await notifier.setRecording(false);
    }

    if (!state.isGuest) {
      if (!discardUnsyncedPoints) {
        final pendingPoints = await ref
            .read(mapStorageProvider)
            .getPendingPointsCount();
        if (pendingPoints > 0) {
          final synced = await ref
              .read(syncServiceProvider)
              .syncPendingPoints();
          if (!synced) return false;
        }
      }
      await ref.read(mapStorageProvider).clearPendingPoints();
    }
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
