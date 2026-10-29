import 'dart:async';

import 'package:globetrottr_front/features/auth/data/auth_service.dart';

/// An auth service without a backend. The session check started when the
/// auth notifier is built waits for [sessionCheck], so a test decides when
/// (and how) it ends.
class FakeAuthService implements AuthService {
  final Completer<String?> sessionCheck = Completer<String?>();

  @override
  Future<String?> refreshToken() => sessionCheck.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
