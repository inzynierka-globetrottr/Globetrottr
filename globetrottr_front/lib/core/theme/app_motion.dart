import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// How a newly chosen tab replaces the old one.
enum TabTransition {
  /// The old tab fades out, then the new one fades in while growing a little.
  fadeThrough,

  /// No animation; only the pill of the navigation moves.
  instant,

  /// The old tab is gone at once and the new one fades in.
  fadeIn,
}

/// How a deeper screen comes in over the one it leaves, built from the
/// page transitions Flutter has.
enum DeeperTransition {
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

/// How the design moves. The scale is taken from the transitions of the
/// mock-up, so every animated element picks a step instead of its own value.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.short,
    required this.medium,
    required this.long,
    required this.flight,
    required this.landing,
    required this.pressHold,
    required this.curve,
    required this.flightCurve,
    required this.tabTransition,
    required this.deeperTransition,
  });

  static const standard = AppMotion(
    short: Duration(milliseconds: 200),
    medium: Duration(milliseconds: 240),
    long: Duration(milliseconds: 280),
    flight: Duration(milliseconds: 450),
    landing: Duration(milliseconds: 1200),
    pressHold: Duration(milliseconds: 100),
    curve: Curves.ease,
    flightCurve: Curves.easeInOut,
    tabTransition: TabTransition.instant,
    deeperTransition: DeeperTransition.zoom,
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

  /// The shortest time a pressed button stays sunk in. A quick tap in a
  /// scrolling list is reported as pressed and released in one frame, which
  /// would never show the press. Not a movement, so reduced motion keeps it.
  final Duration pressHold;

  final Curve curve;
  final Curve flightCurve;
  final TabTransition tabTransition;
  final DeeperTransition deeperTransition;

  /// Every change happens at once, for the system setting that turns
  /// animations off.
  AppMotion get reduced => copyWith(
    short: Duration.zero,
    medium: Duration.zero,
    long: Duration.zero,
    flight: Duration.zero,
    landing: Duration.zero,
  );

  @override
  AppMotion copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? flight,
    Duration? landing,
    Duration? pressHold,
    Curve? curve,
    Curve? flightCurve,
    TabTransition? tabTransition,
    DeeperTransition? deeperTransition,
  }) => AppMotion(
    short: short ?? this.short,
    medium: medium ?? this.medium,
    long: long ?? this.long,
    flight: flight ?? this.flight,
    landing: landing ?? this.landing,
    pressHold: pressHold ?? this.pressHold,
    curve: curve ?? this.curve,
    flightCurve: flightCurve ?? this.flightCurve,
    tabTransition: tabTransition ?? this.tabTransition,
    deeperTransition: deeperTransition ?? this.deeperTransition,
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
      other.pressHold == pressHold &&
      other.curve == curve &&
      other.flightCurve == flightCurve &&
      other.tabTransition == tabTransition &&
      other.deeperTransition == deeperTransition;

  @override
  int get hashCode => Object.hash(
    short,
    medium,
    long,
    flight,
    landing,
    pressHold,
    curve,
    flightCurve,
    tabTransition,
    deeperTransition,
  );
}
