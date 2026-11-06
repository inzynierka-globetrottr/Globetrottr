import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/fade_in_page_transitions.dart';

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
    required this.pressHold,
    required this.curve,
    required this.popCurve,
    required this.flightCurve,
  });

  /// The scale is quicker than the mock-up's CSS transitions, as those felt
  /// sluggish in the app.
  static const standard = AppMotion(
    short: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 180),
    long: Duration(milliseconds: 220),
    flight: Duration(milliseconds: 450),
    landing: Duration(milliseconds: 1200),
    pressHold: Duration(milliseconds: 100),
    curve: Curves.ease,
    popCurve: Curves.easeOutBack,
    flightCurve: Curves.easeInOut,
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

  /// Something popping into place with a slight overshoot, such as the tick
  /// of a met password rule.
  final Curve popCurve;
  final Curve flightCurve;

  /// A screen, a tab or a deeper one, fades in in the short step.
  PageTransitionsTheme get pageTransitions {
    final builder = FadeInPageTransitionsBuilder(
      duration: short,
      curve: curve,
    );
    return PageTransitionsTheme(
      builders: {for (final p in TargetPlatform.values) p: builder},
    );
  }

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
    Curve? popCurve,
    Curve? flightCurve,
  }) => AppMotion(
    short: short ?? this.short,
    medium: medium ?? this.medium,
    long: long ?? this.long,
    flight: flight ?? this.flight,
    landing: landing ?? this.landing,
    pressHold: pressHold ?? this.pressHold,
    curve: curve ?? this.curve,
    popCurve: popCurve ?? this.popCurve,
    flightCurve: flightCurve ?? this.flightCurve,
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
      other.popCurve == popCurve &&
      other.flightCurve == flightCurve;

  @override
  int get hashCode => Object.hash(
    short,
    medium,
    long,
    flight,
    landing,
    pressHold,
    curve,
    popCurve,
    flightCurve,
  );
}
