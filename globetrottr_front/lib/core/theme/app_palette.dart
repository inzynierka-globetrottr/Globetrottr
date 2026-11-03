import 'package:flutter/material.dart';

/// Every colour of the app. Widgets read it through `context.palette`, so a
/// dark palette or another accent changes the whole app without touching
/// widgets.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.text,
    required this.textMuted,
    required this.placeholder,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.shared,
    required this.danger,
    required this.divider,
    required this.dividerHighlight,
    required this.shadowDark,
    required this.shadowLight,
    required this.shadowOverlay,
    required this.shadowPressed,
    required this.fog,
    required this.illustrationBackground,
  });

  static const light = AppPalette(
    background: Color(0xFFE6E3DD),
    text: Color(0xFF1A1C1E),
    textMuted: Color(0xFF4F5359),
    placeholder: Color(0xFF6A6E74),
    accent: Color(0xFF00695C),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFE3A33A),
    shared: Color(0xFF8A8D92),
    danger: Color(0xFFD9531E),
    divider: Color(0xFFD6D1C7),
    dividerHighlight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFF8C8374),
    shadowLight: Color(0xFFFFFFFF),
    shadowOverlay: Color(0xFF14120F),
    shadowPressed: Color(0xFF000000),
    fog: Color(0xDB383633),
    illustrationBackground: Color(0xFFB9D2DC),
  );

  /// Screens and every neumorphic surface on them.
  final Color background;
  final Color text;
  final Color textMuted;
  final Color placeholder;

  /// The one configurable highlight colour.
  final Color accent;

  /// Text and icons drawn on [accent] or [danger].
  final Color onAccent;

  /// The user's own highlights and quest progress.
  final Color gold;

  /// Area shared with a friend.
  final Color shared;

  /// Errors, stopping a recording, rejecting.
  final Color danger;
  final Color divider;

  /// The lit line under a [divider].
  final Color dividerHighlight;

  /// Neumorphic shadow colours, without opacity; each shadow sets its own.
  final Color shadowDark;
  final Color shadowLight;

  /// Shadow of the elements that float over the map.
  final Color shadowOverlay;

  /// The shade a pressed [accent] or [danger] fill sinks into.
  final Color shadowPressed;

  /// Undiscovered area, opacity included.
  final Color fog;

  /// Pastel background for map/voronoi illustrations.
  final Color illustrationBackground;

  @override
  AppPalette copyWith({
    Color? background,
    Color? text,
    Color? textMuted,
    Color? placeholder,
    Color? accent,
    Color? onAccent,
    Color? gold,
    Color? shared,
    Color? danger,
    Color? divider,
    Color? dividerHighlight,
    Color? shadowDark,
    Color? shadowLight,
    Color? shadowOverlay,
    Color? shadowPressed,
    Color? fog,
    Color? illustrationBackground,
  }) => AppPalette(
    background: background ?? this.background,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    placeholder: placeholder ?? this.placeholder,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    gold: gold ?? this.gold,
    shared: shared ?? this.shared,
    danger: danger ?? this.danger,
    divider: divider ?? this.divider,
    dividerHighlight: dividerHighlight ?? this.dividerHighlight,
    shadowDark: shadowDark ?? this.shadowDark,
    shadowLight: shadowLight ?? this.shadowLight,
    shadowOverlay: shadowOverlay ?? this.shadowOverlay,
    shadowPressed: shadowPressed ?? this.shadowPressed,
    fog: fog ?? this.fog,
    illustrationBackground:
        illustrationBackground ?? this.illustrationBackground,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      placeholder: mix(placeholder, other.placeholder),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      gold: mix(gold, other.gold),
      shared: mix(shared, other.shared),
      danger: mix(danger, other.danger),
      divider: mix(divider, other.divider),
      dividerHighlight: mix(dividerHighlight, other.dividerHighlight),
      shadowDark: mix(shadowDark, other.shadowDark),
      shadowLight: mix(shadowLight, other.shadowLight),
      shadowOverlay: mix(shadowOverlay, other.shadowOverlay),
      shadowPressed: mix(shadowPressed, other.shadowPressed),
      fog: mix(fog, other.fog),
      illustrationBackground: mix(
        illustrationBackground,
        other.illustrationBackground,
      ),
    );
  }
}
