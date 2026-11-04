import 'package:flutter/widgets.dart';
import 'package:globetrottr_front/features/friends/screens/add_friend_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friend_map_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friend_profile_screen.dart';
import 'package:go_router/go_router.dart';

/// Locations of the friends' screens. A friend's screens sit under their own
/// segment, so no username can collide with [add], and the username is
/// encoded, so any character a username may hold stays in its segment.
class FriendRoutes {
  FriendRoutes._();

  static const list = '/friends';
  static const add = '/friends/add';

  static const _user = 'user';

  static String profile(String username) =>
      '$list/$_user/${Uri.encodeComponent(username)}';

  static String map(String username, {FriendMapView? view}) =>
      '${profile(username)}/map${view == null ? '' : '?view=${view.name}'}';
}

typedef DeeperRoute =
    GoRoute Function(
      String path,
      Widget Function(GoRouterState state) screen, {
      List<RouteBase> routes,
    });

/// The friends' screens opened above the tabs, under the friends tab.
List<RouteBase> friendDeeperRoutes(DeeperRoute deeper) => [
  deeper('add', (_) => const AddFriendScreen()),
  deeper(
    '${FriendRoutes._user}/:username',
    (state) => FriendProfileScreen(username: state.pathParameters['username']!),
    routes: [
      deeper(
        'map',
        (state) => FriendMapScreen(
          friendUsername: state.pathParameters['username']!,
          initialView: FriendMapView.fromQuery(
            state.uri.queryParameters['view'],
          ),
        ),
      ),
    ],
  ),
];
