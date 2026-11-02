import 'package:intl/intl.dart';

/// An area in km² as a number in the given language; a dash when unknown.
String formatKm2(double? km2, String locale, {int decimals = 2}) {
  if (km2 == null) return '—';
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(km2);
}
