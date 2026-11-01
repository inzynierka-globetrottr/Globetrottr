import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/distance_format.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pl = lookupAppLocalizations(const Locale('pl'));

  group('formatDistance', () {
    test('rounds short distances to ten meters', () {
      expect(formatDistance(0, en), '0 m');
      expect(formatDistance(354, en), '350 m');
      expect(formatDistance(356, en), '360 m');
    });

    test('switches to kilometers once it rounds to a kilometer', () {
      expect(formatDistance(994, en), '990 m');
      expect(formatDistance(996, en), '1.0 km');
    });

    test('keeps one decimal below ten kilometers', () {
      expect(formatDistance(1240, en), '1.2 km');
      expect(formatDistance(9940, en), '9.9 km');
    });

    test('drops the decimals from ten kilometers up', () {
      expect(formatDistance(9960, en), '10 km');
      expect(formatDistance(23400, en), '23 km');
    });

    test('uses the decimal comma in Polish', () {
      expect(formatDistance(1240, pl), '1,2 km');
      expect(formatDistance(350, pl), '350 m');
    });
  });
}
