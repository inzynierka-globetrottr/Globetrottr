import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/core/router/auth_redirect.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/debug/debug_screen.dart';
import 'package:globetrottr_front/debug/dev_options_screen.dart';
import 'package:globetrottr_front/debug/friend_debug_screen.dart';
import 'package:globetrottr_front/debug/preview_screen.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/friends/screens/add_friend_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friend_map_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friends_screen.dart';
import 'package:globetrottr_front/features/map/screens/map_screen.dart';
import 'package:globetrottr_front/features/profile/screens/profile_screen.dart';
import 'package:globetrottr_front/features/quests/screens/quest_history_screen.dart';
import 'package:globetrottr_front/features/quests/screens/quests_screen.dart';
import 'package:go_router/go_router.dart';

class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouter = Provider<GoRouter>((ref) {
  final listenable = AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: AuthRoutes.start,
    refreshListenable: listenable,
    redirect: (context, state) {
      if ((DevConfig.isDevMode || kDebugMode) &&
          state.matchedLocation == '/dev') {
        return null;
      }

      return authRedirect(ref.read(authProvider), state.matchedLocation);
    },
    routes: [
      startRoute,
      authRoute,
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/quests',
        builder: (context, state) => const QuestsScreen(),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => const QuestHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddFriendScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/friends/:username/map',
        builder: (context, state) =>
            FriendMapScreen(friendUsername: state.pathParameters['username']!),
      ),
      if (kDebugMode || DevConfig.isDevMode)
        GoRoute(
          path: '/dev',
          builder: (context, state) => const DevOptionsScreen(),
        ),
      if (kDebugMode)
        GoRoute(
          path: '/debug',
          builder: (context, state) => const DebugScreen(),
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
