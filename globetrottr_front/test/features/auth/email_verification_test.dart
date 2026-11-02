import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

import '../../support/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late ProviderContainer container;
  late DateTime now;

  AuthState current() => container.read(authProvider);

  setUp(() {
    auth = FakeAuthService();
    now = DateTime(2026, 11, 2, 12);
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> register() => container
      .read(authProvider.notifier)
      .register(
        username: 'odkrywca',
        email: ' Odkrywca@Poczta.pl ',
        password: 'Szlak2026!',
      );

  group('registration', () {
    test('waits for the e-mail code instead of signing in', () async {
      await register();

      final state = current();
      expect(auth.registrations.single.email, 'Odkrywca@Poczta.pl');
      expect(state.isAuthenticated, isFalse);
      expect(state.pendingVerificationEmail, 'odkrywca@poczta.pl');
      expect(state.isLoading, isFalse);
    });

    test('a new code can be requested only after the cooldown', () async {
      await register();

      expect(
        current().resendAvailableAt,
        now.add(AuthConfig.resendCooldown),
      );
    });

    test(
      'a failed registration shows the error and waits for nothing',
      () async {
        auth.failWith = const ServerException('Email already exists', 409);

        await register();

        final state = current();
        expect(state.pendingVerificationEmail, isNull);
        expect(state.errorMessage, 'Email already exists');
      },
    );
  });

  group('verification', () {
    test('the right code signs the user in', () async {
      await register();

      await container.read(authProvider.notifier).verifyEmail('482193');

      final state = current();
      expect(auth.verifications.single, (
        email: 'odkrywca@poczta.pl',
        code: '482193',
      ));
      expect(state.isAuthenticated, isTrue);
      expect(state.pendingVerificationEmail, isNull);
    });

    test('a wrong code keeps the user on the code screen', () async {
      await register();
      auth.failWith = const ValidationException(
        'Invalid mail or verification code',
        400,
      );

      await container.read(authProvider.notifier).verifyEmail('000000');

      final state = current();
      expect(state.isAuthenticated, isFalse);
      expect(state.pendingVerificationEmail, 'odkrywca@poczta.pl');
      expect(state.errorMessage, 'Invalid mail or verification code');
    });
  });

  group('sending the code again', () {
    test('is ignored during the cooldown', () async {
      await register();
      now = now.add(AuthConfig.resendCooldown - const Duration(seconds: 1));

      await container.read(authProvider.notifier).resendVerificationCode();

      expect(auth.resentTo, isEmpty);
    });

    test('after the cooldown sends a code and starts a new one', () async {
      await register();
      now = now.add(AuthConfig.resendCooldown);

      await container.read(authProvider.notifier).resendVerificationCode();

      expect(auth.resentTo, ['odkrywca@poczta.pl']);
      expect(
        current().resendAvailableAt,
        now.add(AuthConfig.resendCooldown),
      );
    });
  });
}
