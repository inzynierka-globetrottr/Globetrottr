import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';

void main() {
  group('metersPerPixel', () {
    test('matches the Web Mercator constant at the equator and zoom 0', () {
      expect(
        metersPerPixel(latitude: 0, zoom: 0),
        closeTo(156543.03392, 0.0001),
      );
    });

    test('halves with every zoom level', () {
      final z10 = metersPerPixel(latitude: 0, zoom: 10);
      final z11 = metersPerPixel(latitude: 0, zoom: 11);

      expect(z11, closeTo(z10 / 2, 1e-9));
    });

    test('shrinks with the cosine of latitude', () {
      final equator = metersPerPixel(latitude: 0, zoom: 12);

      expect(
        metersPerPixel(latitude: 60, zoom: 12),
        closeTo(equator / 2, 1e-6),
      );
    });

    test('is symmetric between hemispheres', () {
      expect(
        metersPerPixel(latitude: -50, zoom: 14),
        closeTo(metersPerPixel(latitude: 50, zoom: 14), 1e-9),
      );
    });

    test('supports fractional zoom', () {
      final z15 = metersPerPixel(latitude: 0, zoom: 15);
      final z16 = metersPerPixel(latitude: 0, zoom: 16);
      final mid = metersPerPixel(latitude: 0, zoom: 15.5);

      expect(mid, lessThan(z15));
      expect(mid, greaterThan(z16));
    });
  });

  group('metersToPixels', () {
    test('converts 30 m at Krakow latitude and zoom 16 to about 19.5 px', () {
      expect(
        metersToPixels(meters: 30, latitude: 50.0614, zoom: 16),
        closeTo(19.5, 0.1),
      );
    });

    test('doubles when zoom increases by one', () {
      final z16 = metersToPixels(meters: 30, latitude: 50, zoom: 16);
      final z17 = metersToPixels(meters: 30, latitude: 50, zoom: 17);

      expect(z17, closeTo(z16 * 2, 1e-9));
    });

    test('is zero for zero meters', () {
      expect(metersToPixels(meters: 0, latitude: 50, zoom: 16), 0);
    });
  });
}
