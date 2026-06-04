import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/debug/preview_screen.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/screens/login_screen.dart';
import 'package:globetrottr_front/features/map/screens/map_screen.dart';
import 'package:go_router/go_router.dart';

final authStateProvider = FutureProvider<bool>((ref) async {
  try {
    final token = await AuthService().refreshToken();
    return token != null;
  } catch (_) {
    return false;
  }
});

final appRouter = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final authAsync = ref.read(authStateProvider);

      if (authAsync.isLoading) {
        return null;
      }

      final isStartupAuthed = authAsync.value ?? false;
      final isManualAuthed = ref.read(authProvider).isAuthenticated;
      final isAuthenticated = isStartupAuthed || isManualAuthed;

      final onLoginPage = state.matchedLocation == '/login';

      if (isAuthenticated && onLoginPage) {
        return '/map';
      }
      if (!isAuthenticated && !onLoginPage) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/preview',
          builder: (context, state) => const PreviewScreen(),
        ),
    ],
  );
});