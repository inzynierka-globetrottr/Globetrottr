import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// How a newly chosen tab replaces the old one.
enum TabTransition {
  /// The old tab fades out, then the new one fades in while growing a little.
  fadeThrough,

  /// No animation.
  instant,

  /// The old tab is gone at once and the new one fades in.
  fadeIn,
}

/// How a deeper screen comes in over the one it leaves, built from the
/// page transitions Flutter has.
enum DeeperTransition {
  /// The new screen is there at once, and so is the old one when going back.
  instant,

  /// The whole screen slides in from the right edge, the old one moves a
  /// little to the left, as on iOS.
  slide,

  /// The new screen grows a little from the middle while the old one
  /// recedes, as on Android 10 and later.
  zoom,

  /// The new screen rises a little from the bottom while fading in.
  rise,

  /// Whatever the platform does by default.
  platform;

  PageTransitionsTheme get pageTransitions => switch (this) {
    instant => _everywhere(const _InstantPageTransitionsBuilder()),
    slide => _everywhere(const CupertinoPageTransitionsBuilder()),
    zoom => _everywhere(const ZoomPageTransitionsBuilder()),
    rise => _everywhere(const FadeUpwardsPageTransitionsBuilder()),
    platform => const PageTransitionsTheme(),
  };

  static PageTransitionsTheme _everywhere(PageTransitionsBuilder builder) =>
      PageTransitionsTheme(
        builders: {for (final p in TargetPlatform.values) p: builder},
      );
}

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// How the accent pill of the navigation reaches a newly chosen tab.
enum NavPillMotion {
  /// It slides over the tabs in between.
  slide,

  /// It is under the new tab at once.
  jump,
}

/// How the design moves. Every animated element picks a step of the scale
/// instead of its own value.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.short,
    required this.medium,
    required this.long,
    required this.flight,
    required this.landing,
    required this.pressRise,
    required this.pressHold,
    required this.curve,
    required this.popCurve,
    required this.flightCurve,
    required this.tabTransition,
    required this.deeperTransition,
    required this.navPill,
  });

  /// The scale is quicker than the mock-up's CSS transitions, as those felt
  /// sluggish in the app.
  static const standard = AppMotion(
    short: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 180),
    long: Duration(milliseconds: 220),
    flight: Duration(milliseconds: 450),
    landing: Duration(milliseconds: 1200),
    pressRise: Duration.zero,
    pressHold: Duration(milliseconds: 100),
    curve: Curves.ease,
    popCurve: Curves.easeOutBack,
    flightCurve: Curves.easeInOut,
    tabTransition: TabTransition.fadeIn,
    deeperTransition: DeeperTransition.instant,
    navPill: NavPillMotion.jump,
  );

  /// A press, a fade, a change of colour or shadow.
  final Duration short;

  /// Something folding open or closed, a turning chevron.
  final Duration medium;

  /// A shape growing into another one.
  final Duration long;

  /// The map camera travelling to a place.
  final Duration flight;

  /// The map camera coming down from the overview to the player once the
  /// first position is known.
  final Duration landing;

  /// A released button rising back; it sinks in at once.
  final Duration pressRise;

  /// The shortest time a pressed button stays sunk in. A quick tap in a
  /// scrolling list is reported as pressed and released in one frame, which
  /// would never show the press. Not a movement, so reduced motion keeps it.
  final Duration pressHold;

  final Curve curve;

  /// Something popping into place with a slight overshoot, such as the tick
  /// of a met password rule.
  final Curve popCurve;
  final Curve flightCurve;
  final TabTransition tabTransition;
  final DeeperTransition deeperTransition;
  final NavPillMotion navPill;

  /// Every change happens at once, for the system setting that turns
  /// animations off.
  AppMotion get reduced => copyWith(
    short: Duration.zero,
    medium: Duration.zero,
    long: Duration.zero,
    flight: Duration.zero,
    landing: Duration.zero,
    pressRise: Duration.zero,
  );

  @override
  AppMotion copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? flight,
    Duration? landing,
    Duration? pressRise,
    Duration? pressHold,
    Curve? curve,
    Curve? popCurve,
    Curve? flightCurve,
    TabTransition? tabTransition,
    DeeperTransition? deeperTransition,
    NavPillMotion? navPill,
  }) => AppMotion(
    short: short ?? this.short,
    medium: medium ?? this.medium,
    long: long ?? this.long,
    flight: flight ?? this.flight,
    landing: landing ?? this.landing,
    pressRise: pressRise ?? this.pressRise,
    pressHold: pressHold ?? this.pressHold,
    curve: curve ?? this.curve,
    popCurve: popCurve ?? this.popCurve,
    flightCurve: flightCurve ?? this.flightCurve,
    tabTransition: tabTransition ?? this.tabTransition,
    deeperTransition: deeperTransition ?? this.deeperTransition,
    navPill: navPill ?? this.navPill,
  );

  @override
  AppMotion lerp(AppMotion? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is AppMotion &&
      other.short == short &&
      other.medium == medium &&
      other.long == long &&
      other.flight == flight &&
      other.landing == landing &&
      other.pressRise == pressRise &&
      other.pressHold == pressHold &&
      other.curve == curve &&
      other.popCurve == popCurve &&
      other.flightCurve == flightCurve &&
      other.tabTransition == tabTransition &&
      other.deeperTransition == deeperTransition &&
      other.navPill == navPill;

  @override
  int get hashCode => Object.hash(
    short,
    medium,
    long,
    flight,
    landing,
    pressRise,
    pressHold,
    curve,
    popCurve,
    flightCurve,
    tabTransition,
    deeperTransition,
    navPill,
  );
}
