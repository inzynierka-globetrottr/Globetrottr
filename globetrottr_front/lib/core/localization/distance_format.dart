import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// "350 m" below a kilometer, then "1.2 km" up to ten kilometers and "23 km"
/// beyond, with the decimal separator of the [l10n] locale.
String formatDistance(double meters, AppLocalizations l10n) {
  final roundedMeters = (meters / 10).round() * 10;
  if (roundedMeters < 1000) return l10n.distanceMeters(roundedMeters);

  final kilometers = meters / 1000;
  final decimals = kilometers < 9.95 ? 1 : 0;
  final formatted = NumberFormat.decimalPatternDigits(
    locale: l10n.localeName,
    decimalDigits: decimals,
  ).format(kilometers);
  return l10n.distanceKilometers(formatted);
}
