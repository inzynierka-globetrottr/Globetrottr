import 'package:flutter/foundation.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/debug/friend_debug_screen.dart';
import 'package:globetrottr_front/debug/preview_screen.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/screens/login_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friend_map_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friends_screen.dart';
import 'package:globetrottr_front/features/friends/screens/invite_hub_screen.dart';
import 'package:globetrottr_front/features/map/screens/map_screen.dart';
import 'package:globetrottr_front/features/profile/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';

class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouter = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  final listenable = AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/friends/invites',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const InviteHubScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/friends/:username/map',
        builder: (context, state) =>
            FriendMapScreen(friendUsername: state.pathParameters['username']!),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/preview',
          builder: (context, state) => const PreviewScreen(),
        ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/friends',
          builder: (context, state) => const FriendDebugScreen(),
        ),
    ],
  );
});
