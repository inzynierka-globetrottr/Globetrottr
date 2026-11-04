import 'package:flutter/material.dart';
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
/// moves aside exactly as a screen built by the theme would.
Page<void> fadePage(BuildContext context, GoRouterState state, Widget child) {
  final motion = context.motion;
  return _FadePage(
    key: state.pageKey,
    duration: motion.short,
    curve: motion.curve,
    child: child,
  );
}

class _FadePage extends Page<void> {
  const _FadePage({
    super.key,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _FadeRoute(this);
}

/// A theme-built route with only its own entrance replaced. Flutter lets
/// the theme's transition move the screen below only when both routes are
/// built by it, so a route with a custom transition stays still under a
/// deeper screen.
class _FadeRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _FadeRoute(_FadePage page) : super(settings: page);

  _FadePage get _page => settings as _FadePage;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _page.duration;

  @override
  Duration get reverseTransitionDuration => _page.duration;

  // The builder runs on every frame of both animations, so the curve is
  // driven by a tween, which leaves no listeners on the route's animations.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: animation.drive(CurveTween(curve: _page.curve)),
    child: super.buildTransitions(
      context,
      kAlwaysCompleteAnimation,
      secondaryAnimation,
      child,
    ),
  );
}
