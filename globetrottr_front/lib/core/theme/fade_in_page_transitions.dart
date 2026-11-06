import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// Every screen comes in as a newly chosen tab does: the screen it covers is
/// gone at once under the page colour, and the new one fades in on it.
/// Going back is the same the other way: the closed screen is gone at once
/// and the one below fades in.
@immutable
class FadeInPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeInPageTransitionsBuilder({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FadeIn(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    curve: curve,
    child: child,
  );

  @override
  bool operator ==(Object other) =>
      other is FadeInPageTransitionsBuilder &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({
    required this.animation,
    required this.secondaryAnimation,
    required this.curve,
    required this.child,
  });

  final Animation<double> animation;

  /// The animation of the screen above; going back from it, this screen
  /// fades in again.
  final Animation<double> secondaryAnimation;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The length of the route comes from the app theme, which the system
    // setting that turns animations off does not reach, so then the screen
    // is fully shown at once instead.
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fade = CurveTween(curve: curve);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, page) => Offstage(
        offstage: animation.status == AnimationStatus.reverse,
        child: page,
      ),
      child: ColoredBox(
        color: context.palette.background,
        child: FadeTransition(
          opacity: disabled
              ? kAlwaysCompleteAnimation
              : AnimationMin(
                  animation.drive(fade),
                  ReverseAnimation(secondaryAnimation).drive(fade),
                ),
          child: child,
        ),
      ),
    );
  }
}
