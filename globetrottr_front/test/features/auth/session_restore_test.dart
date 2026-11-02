import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_location_service.dart';

void main() {
  late FakeAuthService auth;

  ProviderContainer start() {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        syncServiceProvider.overrideWithValue(FakeSyncService()),
      ],
    );
    addTearDown(container.dispose);
    container.read(authProvider);
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    auth = FakeAuthService();
  });

  test('a stored token enters the app before the backend answers', () async {
    auth.storedToken = true;
    final container = start();
    await settle();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isInitializing, isFalse);
  });

  test('without a stored token the user is out at once', () async {
    final container = start();
    await settle();

    final state = container.read(authProvider);
    expect(state.canEnterApp, isFalse);
    expect(state.isInitializing, isFalse);
  });

  test('being offline keeps the stored session', () async {
    auth.storedToken = true;
    final container = start();
    await settle();

    auth.sessionCheck.completeError(const NetworkException());
    await settle();

    expect(container.read(authProvider).isAuthenticated, isTrue);
    expect(auth.logouts, 0);
  });

  test('a token the backend rejects signs the user out', () async {
    auth.storedToken = true;
    final container = start();
    await settle();

    auth.sessionCheck.completeError(const UnauthorizedException());
    await settle();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isFalse);
    expect(state.isInitializing, isFalse);
    expect(auth.logouts, 1);
  });
}
