import 'package:globetrottr_front/core/router/app_pages.dart';
import 'package:globetrottr_front/features/auth/screens/login_screen.dart';
import 'package:globetrottr_front/features/auth/screens/register_screen.dart';
import 'package:globetrottr_front/features/auth/screens/reset_password_code_screen.dart';
import 'package:globetrottr_front/features/auth/screens/reset_password_screen.dart';
import 'package:globetrottr_front/features/auth/screens/start_screen.dart';
import 'package:globetrottr_front/features/auth/screens/verify_email_screen.dart';
import 'package:go_router/go_router.dart';

/// Locations of the screens open without an account. They are nested under
/// [login], so going back follows the routes rather than a pushed history,
/// and a redirect replaces the whole stack once the user is in.
class AuthRoutes {
  AuthRoutes._();

  /// Shown while the stored session is read, before the app knows whether
  /// to open the map or the login.
  static const start = '/start';
  static const login = '/login';
  static const register = '/login/register';
  static const verify = '/login/register/verify';
  static const reset = '/login/reset';
  static const resetCode = '/login/reset/code';
}

final startRoute = GoRoute(
  path: AuthRoutes.start,
  builder: (context, state) => const StartScreen(),
);

final authRoute = GoRoute(
  path: AuthRoutes.login,
  pageBuilder: (context, state) =>
      fadePage(context, state, const LoginScreen()),
  routes: [
    GoRoute(
      path: 'register',
      pageBuilder: (context, state) =>
          deeperPage(context, state, const RegisterScreen()),
      routes: [
        GoRoute(
          path: 'verify',
          pageBuilder: (context, state) =>
              deeperPage(context, state, const VerifyEmailScreen()),
        ),
      ],
    ),
    GoRoute(
      path: 'reset',
      pageBuilder: (context, state) =>
          deeperPage(context, state, const ResetPasswordScreen()),
      routes: [
        GoRoute(
          path: 'code',
          pageBuilder: (context, state) => deeperPage(
            context,
            state,
            ResetPasswordCodeScreen(email: state.extra as String? ?? ''),
          ),
        ),
      ],
    ),
  ],
);
