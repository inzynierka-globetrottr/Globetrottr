import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
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

  /// Decides from the device alone, so the app opens without waiting for
  /// the network; the stored token is refreshed afterwards. A session check
  /// never logs out a user who got in while it was running.
  Future<void> _checkExistingSession() async {
    final guest = await _storedGuest();
    if (!ref.mounted) return;
    if (guest) {
      state = state.copyWith(isGuest: true, isInitializing: false);
      return;
    }
    final hasToken = await _storedToken();
    if (!ref.mounted) return;
    if (hasToken) await _enterAccount();
    if (!ref.mounted) return;
    state = state.copyWith(isInitializing: false);
    if (hasToken) unawaited(_refreshSession());
  }

  /// Offline the stored token keeps the user in; only the backend rejecting
  /// it ends the session.
  Future<void> _refreshSession() async {
    try {
      await _authService.refreshToken();
    } on UnauthorizedException {
      await _endRejectedSession();
    } on ForbiddenException {
      await _endRejectedSession();
    } catch (e) {
      debugPrint('Could not refresh the session: $e');
    }
  }

  /// Pending points stay for the next sign-in, as the backend cannot take
  /// them without a valid token.
  Future<void> _endRejectedSession() async {
    if (!ref.mounted || !state.isAuthenticated) return;
    await _stopRecording();
    await _signOut();
  }

  Future<bool> _storedToken() async {
    try {
      return await _authService.hasStoredToken();
    } catch (e) {
      debugPrint('Could not read the stored token: $e');
      return false;
    }
  }

  /// An account wins over a guest chosen in the meantime, so the two never
  /// hold at once and a logout still syncs and clears the account's points.
  Future<void> _enterAccount() async {
    if (state.isGuest) {
      try {
        await _authService.endGuestSession();
      } catch (e) {
        debugPrint('Could not forget the guest choice: $e');
      }
    }
    state = state.copyWith(isAuthenticated: true, isGuest: false);
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
  /// works; calls to the backend fail as when offline. Ignored while signing
  /// in.
  Future<void> continueAsGuest() async {
    if (state.isLoading || state.isAuthenticated) return;
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
      _run(AuthForm.login, () async {
        await _authService.login(
          LoginRequest(login: login.trim(), password: password),
        );
        await _enterAccount();
      });

  /// A new account is locked until its e-mail is verified with a code.
  /// Returns whether the code was sent.
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) => _run(AuthForm.register, () async {
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
    await _run(AuthForm.verify, () async {
      await _authService.verifyEmail(email: email, code: code);
      state = state.copyWith(clearVerification: true);
      await _enterAccount();
    });
  }

  /// Ignored until [AuthState.resendAvailableAt].
  Future<void> resendVerificationCode() async {
    final email = state.pendingVerificationEmail;
    final availableAt = state.resendAvailableAt;
    if (email == null) return;
    if (availableAt != null && _now.isBefore(availableAt)) return;
    await _run(AuthForm.verify, () async {
      await _authService.resendVerificationCode(email);
      state = state.copyWith(
        resendAvailableAt: _now.add(AuthConfig.resendCooldown),
      );
    });
  }

  /// [form] is the screen that shows a failure.
  Future<void> signInWithGoogle(AuthForm form) => _run(form, () async {
    final token = await _authService.signInWithGoogle();
    if (token != null) await _enterAccount();
  });

  /// Shows progress while [action] runs and turns its failure into an error
  /// message of [form]. Returns whether it succeeded.
  Future<bool> _run(AuthForm form, Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorForm: form,
      );
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
        errorForm: form,
      );
    }
    return false;
  }

  /// A guest has nothing to sync; a signed-in user's pending points are sent
  /// first unless [discardUnsyncedPoints].
  Future<bool> logout({bool discardUnsyncedPoints = false}) async {
    await _stopRecording();

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
    await _signOut();
    return true;
  }

  Future<void> _stopRecording() async {
    if (ref.read(locationProvider).isRecording) {
      await ref.read(locationProvider.notifier).setRecording(false);
    }
  }

  Future<void> _signOut() async {
    await _authService.logout();

    ref.invalidate(locationProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(friendsProvider);
    ref.invalidate(friendFogProvider);
    ref.invalidate(questsProvider);

    state = const AuthState(isInitializing: false);
  }
}
