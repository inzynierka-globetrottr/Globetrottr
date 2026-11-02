import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_location_service.dart';

void main() {
  late FakeAuthService auth;
  late FakeSyncService sync;

  ProviderContainer start() {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        syncServiceProvider.overrideWithValue(sync),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    auth = FakeAuthService();
    sync = FakeSyncService();
  });

  test('skipping the login enters the app without a backend', () async {
    final container = start();

    await container.read(authProvider.notifier).continueAsGuest();

    final state = container.read(authProvider);
    expect(state.isGuest, isTrue);
    expect(state.canEnterApp, isTrue);
    expect(state.isAuthenticated, isFalse);
    expect(state.isInitializing, isFalse);
    expect(auth.guest, isTrue);
  });

  test('the guest choice is remembered on the next start', () async {
    auth.guest = true;
    final container = start();
    container.read(authProvider);
    auth.sessionCheck.complete(null);
    await settle();

    final state = container.read(authProvider);
    expect(state.isGuest, isTrue);
    expect(state.canEnterApp, isTrue);
    expect(state.isInitializing, isFalse);
  });

  test('a session check that ends later does not throw a guest out', () async {
    final container = start();
    container.read(authProvider);
    await container.read(authProvider.notifier).continueAsGuest();
    auth.sessionCheck.complete(null);
    await settle();

    expect(container.read(authProvider).canEnterApp, isTrue);
  });

  test('without an account or the guest choice the user stays out', () async {
    final container = start();
    container.read(authProvider);
    auth.sessionCheck.complete(null);
    await settle();

    final state = container.read(authProvider);
    expect(state.canEnterApp, isFalse);
    expect(state.isInitializing, isFalse);
  });

  test('leaving guest mode forgets the choice and syncs nothing', () async {
    final container = start();
    await container.read(authProvider.notifier).continueAsGuest();

    final left = await container.read(authProvider.notifier).logout();

    expect(left, isTrue);
    expect(auth.guest, isFalse);
    expect(sync.calls, 0);
    expect(container.read(authProvider).canEnterApp, isFalse);
  });

  test('an account found after skipping replaces the guest', () async {
    final container = start();
    container.read(authProvider);
    // The check is now waiting for the backend.
    await settle();
    await container.read(authProvider.notifier).continueAsGuest();
    auth.sessionCheck.complete('token');
    await settle();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isGuest, isFalse);
    expect(auth.guest, isFalse);
  });

  test('skipping is ignored while signing in', () async {
    final container = start();
    final notifier = container.read(authProvider.notifier);
    auth.loginGate = Completer<void>();

    final signingIn = notifier.login(login: 'odkrywca', password: 'Szlak26!');
    await notifier.continueAsGuest();
    auth.loginGate!.complete();
    await signingIn;

    final state = container.read(authProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isGuest, isFalse);
    expect(auth.guest, isFalse);
  });
}
