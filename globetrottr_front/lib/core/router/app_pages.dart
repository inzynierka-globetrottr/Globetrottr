import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:go_router/go_router.dart';

/// A screen one level deeper. It comes in with the page transition of the
/// theme, which the motion chooses, and goes back the same way.
Page<void> deeperPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => MaterialPage<void>(key: state.pageKey, child: child);

/// A screen that replaces another one at the same level, such as the map
/// after signing in: it fades in. When a deeper screen comes over it, it
/// moves aside as the chosen transition expects of the screen below.
Page<void> fadePage(BuildContext context, GoRouterState state, Widget child) {
  final motion = context.motion;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: motion.short,
    reverseTransitionDuration: motion.short,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: motion.curve),
          child: _belowDeeper(
            motion.deeperTransition,
            secondaryAnimation,
            child,
          ),
        ),
  );
}

/// The part a page transition plays on the screen below, for pages that
/// are not built by the theme.
Widget _belowDeeper(
  DeeperTransition transition,
  Animation<double> covered,
  Widget child,
) => switch (transition) {
  DeeperTransition.slide => SlideTransition(
    position: Tween(
      begin: Offset.zero,
      end: const Offset(-1 / 3, 0),
    ).animate(CurvedAnimation(parent: covered, curve: Curves.linearToEaseOut)),
    child: child,
  ),
  DeeperTransition.zoom => ScaleTransition(
    scale: Tween(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: covered, curve: Curves.fastOutSlowIn)),
    child: child,
  ),
  DeeperTransition.rise || DeeperTransition.platform => child,
};
