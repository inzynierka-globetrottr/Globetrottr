import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';

/// The text styles of the design, named by role. Colours come from the
/// palette; a widget changes only the colour when it needs another one.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display,
    required this.headline,
    required this.digit,
    required this.titleLarge,
    required this.title,
    required this.button,
    required this.value,
    required this.input,
    required this.itemTitle,
    required this.bodyLarge,
    required this.action,
    required this.body,
    required this.label,
    required this.note,
    required this.captionStrong,
    required this.caption,
    required this.sectionLabel,
    required this.small,
    required this.smallStrong,
    required this.statHero,
    required this.statValue,
    required this.valueLarge,
    required this.micro,
  });

  factory AppTypography.fromPalette(AppPalette palette) {
    TextStyle style(
      double size,
      FontWeight weight, {
      Color? color,
      double letterSpacingEm = 0,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacingEm * size,
      color: color ?? palette.text,
    );

    final muted = palette.textMuted;
    return AppTypography(
      display: style(32, FontWeight.w800, letterSpacingEm: -0.03),
      headline: style(30, FontWeight.w800, letterSpacingEm: -0.02),
      digit: style(26, FontWeight.w800),
      titleLarge: style(24, FontWeight.w800, letterSpacingEm: -0.01),
      title: style(22, FontWeight.w800, letterSpacingEm: -0.01),
      button: style(17, FontWeight.w800, color: palette.onAccent),
      value: style(16, FontWeight.w800),
      input: style(16, FontWeight.w700),
      itemTitle: style(15, FontWeight.w800),
      bodyLarge: style(15, FontWeight.w600, color: muted),
      action: style(14, FontWeight.w800),
      body: style(14, FontWeight.w600, color: muted),
      label: style(13, FontWeight.w800),
      note: style(13, FontWeight.w700, color: muted),
      captionStrong: style(12, FontWeight.w800),
      caption: style(12, FontWeight.w700, color: muted),
      sectionLabel: style(
        12,
        FontWeight.w800,
        color: muted,
        letterSpacingEm: 0.12,
      ),
      small: style(11, FontWeight.w700, color: muted),
      smallStrong: style(11, FontWeight.w800, color: muted),
      statHero: style(38, FontWeight.w800, letterSpacingEm: -0.03),
      statValue: style(21, FontWeight.w800),
      valueLarge: style(17, FontWeight.w800),
      micro: style(10, FontWeight.w800, color: muted),
    );
  }

  static const fontFamily = 'Manrope';

  /// Bold Manrope under its own family name, for map labels: the map
  /// renderer picks a font by family only, without a weight.
  static const mapBoldFontFamily = 'Manrope Bold';

  /// Logo and the largest titles.
  final TextStyle display;

  /// Screen titles.
  final TextStyle headline;

  /// One digit of a code.
  final TextStyle digit;

  /// Sheet titles.
  final TextStyle titleLarge;
  final TextStyle title;

  /// Label of a button filled with the accent.
  final TextStyle button;

  /// Values and option names.
  final TextStyle value;
  final TextStyle input;

  /// Names in lists and labels of secondary buttons.
  final TextStyle itemTitle;

  /// Subtitles under a title.
  final TextStyle bodyLarge;

  /// Small pill buttons and text actions.
  final TextStyle action;
  final TextStyle body;

  /// Field labels, links and card titles.
  final TextStyle label;

  /// Hints under a field.
  final TextStyle note;
  final TextStyle captionStrong;
  final TextStyle caption;

  /// Section headers; written in capitals.
  final TextStyle sectionLabel;
  final TextStyle small;
  final TextStyle smallStrong;

  /// The large count of a statistics banner.
  final TextStyle statHero;

  /// Values of statistics tiles and records.
  final TextStyle statValue;

  /// Names and values a step above [value], like a country in a list.
  final TextStyle valueLarge;

  /// Axis labels and flag codes.
  final TextStyle micro;

  List<TextStyle> get all => [
    display,
    headline,
    digit,
    titleLarge,
    title,
    button,
    value,
    input,
    itemTitle,
    bodyLarge,
    action,
    body,
    label,
    note,
    captionStrong,
    caption,
    sectionLabel,
    small,
    smallStrong,
    statHero,
    statValue,
    valueLarge,
    micro,
  ];

  /// Rebuilding from a palette is the only change the app needs.
  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      display: mix(display, other.display),
      headline: mix(headline, other.headline),
      digit: mix(digit, other.digit),
      titleLarge: mix(titleLarge, other.titleLarge),
      title: mix(title, other.title),
      button: mix(button, other.button),
      value: mix(value, other.value),
      input: mix(input, other.input),
      itemTitle: mix(itemTitle, other.itemTitle),
      bodyLarge: mix(bodyLarge, other.bodyLarge),
      action: mix(action, other.action),
      body: mix(body, other.body),
      label: mix(label, other.label),
      note: mix(note, other.note),
      captionStrong: mix(captionStrong, other.captionStrong),
      caption: mix(caption, other.caption),
      sectionLabel: mix(sectionLabel, other.sectionLabel),
      small: mix(small, other.small),
      smallStrong: mix(smallStrong, other.smallStrong),
      statHero: mix(statHero, other.statHero),
      statValue: mix(statValue, other.statValue),
      valueLarge: mix(valueLarge, other.valueLarge),
      micro: mix(micro, other.micro),
    );
  }
}
