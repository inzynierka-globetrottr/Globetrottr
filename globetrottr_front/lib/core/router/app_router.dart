import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/core/router/app_pages.dart';
import 'package:globetrottr_front/core/router/app_tabs.dart';
import 'package:globetrottr_front/core/router/auth_redirect.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/core/router/friend_routes.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/debug/animations/animations_screen.dart';
import 'package:globetrottr_front/debug/debug_screen.dart';
import 'package:globetrottr_front/debug/dev_options_screen.dart';
import 'package:globetrottr_front/debug/friend_debug_screen.dart';
import 'package:globetrottr_front/debug/preview_screen.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
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

/// Deeper screens are shown here, above the tabs and their navigation.
final _rootNavigator = GlobalKey<NavigatorState>();

GoRoute _deeper(
  String path,
  Widget Function(GoRouterState state) screen, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  parentNavigatorKey: _rootNavigator,
  routes: routes,
  pageBuilder: (context, state) => deeperPage(context, state, screen(state)),
);

StatefulShellBranch _tab(
  NavbarItem item,
  Widget screen, {
  List<RouteBase> deeper = const [],
}) => StatefulShellBranch(
  routes: [
    GoRoute(path: item.route, builder: (_, _) => screen, routes: deeper),
  ],
);

final appRouter = Provider<GoRouter>((ref) {
  final listenable = AuthNotifierListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigator,
    initialLocation: AuthRoutes.start,
    refreshListenable: listenable,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if ((DevConfig.isDevMode || kDebugMode) &&
          (location == '/dev' || location.startsWith('/dev/'))) {
        return null;
      }

      return authRedirect(ref.read(authProvider), state.matchedLocation);
    },
    routes: [
      startRoute,
      authRoute,
      appTabs([
        _tab(NavbarItem.map, const MapScreen()),
        _tab(
          NavbarItem.quests,
          const QuestsScreen(),
          deeper: [_deeper('history', (_) => const QuestHistoryScreen())],
        ),
        _tab(
          NavbarItem.friends,
          const FriendsScreen(),
          deeper: friendDeeperRoutes(_deeper),
        ),
        _tab(NavbarItem.profile, const ProfileScreen()),
      ]),
      if (kDebugMode || DevConfig.isDevMode)
        GoRoute(
          path: '/dev',
          pageBuilder: (context, state) =>
              deeperPage(context, state, const DevOptionsScreen()),
          routes: [
            _deeper('animations', (_) => const AnimationsScreen()),
          ],
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
