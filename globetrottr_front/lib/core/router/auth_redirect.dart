import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

/// Where [location] leads for the given auth state; null keeps it.
String? authRedirect(AuthState auth, String location) {
  if (auth.isInitializing) return null;

  final onAuthScreen = location.startsWith(AuthRoutes.login);
  if (auth.canEnterApp) return onAuthScreen ? '/map' : null;
  if (!onAuthScreen) return AuthRoutes.login;
  if (location == AuthRoutes.verify && auth.pendingVerificationEmail == null) {
    return AuthRoutes.login;
  }
  return null;
}
