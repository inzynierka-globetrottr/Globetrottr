import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/auth_redirect.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

void main() {
  const signedOut = AuthState(isInitializing: false);
  const signedIn = AuthState(isInitializing: false, isAuthenticated: true);
  const guest = AuthState(isInitializing: false, isGuest: true);
  const verifying = AuthState(
    isInitializing: false,
    pendingVerificationEmail: 'odkrywca@poczta.pl',
  );

  test('nothing moves while the session is being checked', () {
    expect(authRedirect(const AuthState(), '/map'), isNull);
    expect(authRedirect(const AuthState(), AuthRoutes.start), isNull);
  });

  test('the start screen leads to the map or to the login', () {
    expect(authRedirect(signedIn, AuthRoutes.start), '/map');
    expect(authRedirect(guest, AuthRoutes.start), '/map');
    expect(authRedirect(signedOut, AuthRoutes.start), AuthRoutes.login);
  });

  test('a signed-out user may open every auth screen but verification', () {
    for (final location in [
      AuthRoutes.login,
      AuthRoutes.register,
      AuthRoutes.reset,
      AuthRoutes.resetCode,
    ]) {
      expect(authRedirect(signedOut, location), isNull, reason: location);
    }
    expect(authRedirect(signedOut, AuthRoutes.verify), AuthRoutes.login);
  });

  test('the app itself needs an account or the guest choice', () {
    expect(authRedirect(signedOut, '/map'), AuthRoutes.login);
    expect(authRedirect(signedOut, '/friends'), AuthRoutes.login);
    expect(authRedirect(guest, '/map'), isNull);
    expect(authRedirect(signedIn, '/profile'), isNull);
  });

  test('an account waiting for its code may open verification', () {
    expect(authRedirect(verifying, AuthRoutes.verify), isNull);
  });

  test('whoever is in leaves the auth screens for the map', () {
    expect(authRedirect(signedIn, AuthRoutes.login), '/map');
    expect(authRedirect(guest, AuthRoutes.register), '/map');
    expect(authRedirect(signedIn, AuthRoutes.verify), '/map');
  });
}
