import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';

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
}
