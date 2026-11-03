import 'package:flutter/material.dart';

/// How the design moves. The scale is taken from the transitions of the
/// mock-up, so every animated element picks a step instead of its own value.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.short,
    required this.medium,
    required this.long,
    required this.flight,
    required this.curve,
    required this.flightCurve,
  });

  static const standard = AppMotion(
    short: Duration(milliseconds: 200),
    medium: Duration(milliseconds: 240),
    long: Duration(milliseconds: 280),
    flight: Duration(milliseconds: 450),
    curve: Curves.ease,
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

  final Curve curve;
  final Curve flightCurve;

  /// Every change happens at once, for the system setting that turns
  /// animations off.
  AppMotion get reduced => copyWith(
    short: Duration.zero,
    medium: Duration.zero,
    long: Duration.zero,
    flight: Duration.zero,
  );

  @override
  AppMotion copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? flight,
    Curve? curve,
    Curve? flightCurve,
  }) => AppMotion(
    short: short ?? this.short,
    medium: medium ?? this.medium,
    long: long ?? this.long,
    flight: flight ?? this.flight,
    curve: curve ?? this.curve,
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
      other.curve == curve &&
      other.flightCurve == flightCurve;

  @override
  int get hashCode =>
      Object.hash(short, medium, long, flight, curve, flightCurve);
}
