import 'dart:math' as math;

import 'package:intl/intl.dart';

const _unknown = '—';

/// A number with [decimals] decimals in the given language; a dash when
/// unknown.
String formatNumber(double? value, String locale, {int decimals = 0}) {
  if (value == null) return _unknown;
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(value);
}

/// An area in km² as a number in the given language; a dash when unknown.
String formatKm2(double? km2, String locale, {int decimals = 2}) =>
    formatNumber(km2, locale, decimals: decimals);

/// A share (0 to 1) as a percent, without the sign, whole unless [decimals]
/// are asked for in [locale]; a dash when unknown.
String formatPercent(double? share, {String? locale, int decimals = 0}) {
  if (share == null) return _unknown;
  if (decimals == 0) return (share * 100).round().toString();
  return formatNumber(share * 100, locale ?? 'en', decimals: decimals);
}

/// A positive number rounded to [digits] significant digits, so a tiny share
/// stays readable; a dash when unknown.
String formatSignificant(double? value, String locale, {int digits = 2}) {
  if (value == null) return _unknown;
  if (value == 0) return '0';
  // The exponent after rounding, so 9.96 counts as 10.
  final magnitude = int.parse(
    value.abs().toStringAsExponential(digits - 1).split('e').last,
  );
  return formatNumber(
    value,
    locale,
    decimals: math.max(0, digits - 1 - magnitude),
  );
}

/// A day with the full month, as it follows "since", with the year when it is
/// not [now]'s year, e.g. "2 marca" or "March 2, 2025".
String formatSinceDate(DateTime date, String locale, {DateTime? now}) {
  final sameYear = date.year == (now ?? DateTime.now()).year;
  return (sameYear ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale))
      .format(date);
}

/// A short month on its own, e.g. "Sep" or "wrz".
String formatShortMonth(DateTime date, String locale) =>
    DateFormat('LLL', locale).format(date);

/// A day with a short month, e.g. "28 Sep" or "28 wrz".
String formatShortDate(DateTime date, String locale) =>
    DateFormat('d MMM', locale).format(date);

/// The name of a month, with the year when it is not [now]'s year.
String formatMonth(DateTime date, String locale, {DateTime? now}) {
  final sameYear = date.year == (now ?? DateTime.now()).year;
  return DateFormat(sameYear ? 'LLLL' : 'LLLL y', locale).format(date);
}

/// A distance in metres, or in kilometres from one kilometre on.
String formatDistance(double? meters, String locale) {
  if (meters == null) return '$_unknown m';
  if (meters < 1000) return '${meters.round()} m';
  return '${formatNumber(meters / 1000, locale, decimals: 1)} km';
}
