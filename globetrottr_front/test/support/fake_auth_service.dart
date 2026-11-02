import 'dart:async';

import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/data/login_request.dart';
import 'package:globetrottr_front/features/auth/data/register_request.dart';

/// An auth service without a backend. The session check started when the
/// auth notifier is built waits for [sessionCheck], so a test decides when
/// (and how) it ends.
class FakeAuthService implements AuthService {
  final Completer<String?> sessionCheck = Completer<String?>();

  /// The stored guest choice.
  bool guest = false;

  /// Thrown by the next backend call instead of succeeding.
  AppException? failWith;

  /// When set, a login waits for it instead of succeeding at once.
  Completer<void>? loginGate;

  final List<LoginRequest> logins = [];
  final List<RegisterRequest> registrations = [];
  final List<({String email, String code})> verifications = [];
  final List<String> resentTo = [];
  int logouts = 0;

  @override
  Future<String?> refreshToken() => sessionCheck.future;

  @override
  Future<bool> isGuest() async => guest;

  @override
  Future<void> startGuestSession() async => guest = true;

  @override
  Future<void> endGuestSession() async => guest = false;

  @override
  Future<String> login(LoginRequest request) async {
    _maybeFail();
    logins.add(request);
    await loginGate?.future;
    return 'token';
  }

  @override
  Future<void> register(RegisterRequest request) async {
    _maybeFail();
    registrations.add(request);
  }

  @override
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    _maybeFail();
    verifications.add((email: email, code: code));
    return 'token';
  }

  @override
  Future<void> resendVerificationCode(String email) async {
    _maybeFail();
    resentTo.add(email);
  }

  @override
  Future<void> logout() async {
    logouts++;
    guest = false;
  }

  void _maybeFail() {
    final error = failWith;
    failWith = null;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
