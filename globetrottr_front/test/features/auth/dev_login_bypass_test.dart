import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';

import '../../support/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
  });

  test('entering without login authenticates without a backend', () {
    container.read(authProvider.notifier).enterWithoutLogin();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isInitializing, isFalse);
  });

  test('a session check that fails later does not log the user out', () async {
    container.read(authProvider);
    await Future<void>.delayed(Duration.zero);

    container.read(authProvider.notifier).enterWithoutLogin();
    auth.sessionCheck.complete(null);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authProvider).isAuthenticated, isTrue);
  });

  test(
    'without the bypass a failed session check leaves the user out',
    () async {
      container.read(authProvider);
      auth.sessionCheck.complete(null);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isInitializing, isFalse);
    },
  );
}
