import 'package:intl/intl.dart';

const _unknown = '—';

/// An area in km² as a number in the given language; a dash when unknown.
String formatKm2(double? km2, String locale, {int decimals = 2}) {
  if (km2 == null) return _unknown;
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(km2);
}

/// A share (0 to 1) as a whole percent, without the sign; a dash when
/// unknown.
String formatPercent(double? share) {
  if (share == null) return _unknown;
  return (share * 100).round().toString();
}

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
  return '${formatKm2(meters / 1000, locale, decimals: 1)} km';
}
