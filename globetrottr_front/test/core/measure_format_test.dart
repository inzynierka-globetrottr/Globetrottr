import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('area', () {
    test('uses the decimal separator of the language', () {
      expect(formatKm2(0.92, 'pl'), '0,92');
      expect(formatKm2(0.92, 'en'), '0.92');
    });

    test('keeps the requested number of decimals', () {
      expect(formatKm2(15.2, 'pl', decimals: 1), '15,2');
      expect(formatKm2(3, 'pl', decimals: 1), '3,0');
    });

    test('an unknown area is a dash', () {
      expect(formatKm2(null, 'pl'), '—');
    });
  });

  group('percent', () {
    test('a share becomes a whole percent', () {
      expect(formatPercent(0.184), '18');
      expect(formatPercent(1), '100');
    });

    test('an unknown share is a dash', () {
      expect(formatPercent(null), '—');
    });
  });

  group('distance', () {
    test('short distances are whole metres', () {
      expect(formatDistance(280.4, 'pl'), '280 m');
    });

    test('from a kilometre on, kilometres with one decimal', () {
      expect(formatDistance(1240, 'pl'), '1,2 km');
      expect(formatDistance(1240, 'en'), '1.2 km');
    });

    test('an unknown distance is a dash', () {
      expect(formatDistance(null, 'pl'), '— m');
    });
  });

  group('significant digits', () {
    test('a tiny share keeps two significant digits', () {
      expect(formatSignificant(0.0000083255, 'pl'), '0,0000083');
      expect(formatSignificant(0.0000083255, 'en'), '0.0000083');
    });

    test('a large value drops its decimals', () {
      expect(formatSignificant(12.4, 'en'), '12');
      expect(formatSignificant(1.24, 'en'), '1.2');
    });

    test('zero and unknown values', () {
      expect(formatSignificant(0, 'en'), '0');
      expect(formatSignificant(null, 'en'), '—');
    });
  });

  group('month', () {
    setUpAll(initializeDateFormatting);

    test('a short month stands on its own', () {
      expect(formatShortMonth(DateTime(2026, 9, 14), 'pl'), 'wrz');
      expect(formatShortMonth(DateTime(2026, 10, 5), 'pl'), 'paź');
      expect(formatShortMonth(DateTime(2026, 9, 14), 'en'), 'Sep');
    });

    test('friends since uses the day and the month of a date', () {
      final now = DateTime(2026, 11, 4);
      expect(formatSinceDate(DateTime(2026, 3, 2), 'pl', now: now), '2 marca');
      expect(formatSinceDate(DateTime(2026, 3, 2), 'en', now: now), 'March 2');
      expect(
        formatSinceDate(DateTime(2025, 3, 2), 'pl', now: now),
        '2 marca 2025',
      );
    });
  });
}
