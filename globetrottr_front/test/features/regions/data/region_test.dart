import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';

import '../../../support/region_geometry_encoder.dart';

void main() {
  group('Region.containsPoint', () {
    test('returns false when point is outside bounding box', () {
      const region = Region(
        id: 1,
        parentId: null,
        name: 'Test',
        type: RegionType.city,
        code: null,
        totalAreaKm2: 100.0,
        minLat: 10.0,
        maxLat: 20.0,
        minLon: 10.0,
        maxLon: 20.0,
      );

      expect(region.containsPoint(5.0, 15.0), isFalse);
      expect(region.containsPoint(25.0, 15.0), isFalse);
      expect(region.containsPoint(15.0, 5.0), isFalse);
      expect(region.containsPoint(15.0, 25.0), isFalse);
    });

    test('returns true when inside bbox and geometry is null', () {
      const region = Region(
        id: 1,
        parentId: null,
        name: 'Test',
        type: RegionType.city,
        code: null,
        totalAreaKm2: 100.0,
        minLat: 10.0,
        maxLat: 20.0,
        minLon: 10.0,
        maxLon: 20.0,
      );

      expect(region.containsPoint(15.0, 15.0), isTrue);
    });

    test('verifies accurate point-in-polygon using geometry BLOB', () {
      // Right triangle: (10, 10), (20, 10), (10, 20)
      // Points inside: (12, 12)
      // Points outside triangle but inside bbox: (18, 18)
      final triangleGeom = encodeRegionGeometry([
        [(10.0, 10.0), (20.0, 10.0), (10.0, 20.0), (10.0, 10.0)],
      ]);

      final region = Region(
        id: 1,
        parentId: null,
        name: 'Triangle',
        type: RegionType.city,
        code: null,
        totalAreaKm2: 50.0,
        minLat: 10.0,
        maxLat: 20.0,
        minLon: 10.0,
        maxLon: 20.0,
        geometry: triangleGeom,
      );

      expect(region.containsPoint(12.0, 12.0), isTrue);
      expect(region.containsPoint(18.0, 18.0), isFalse);
    });
  });

  group('Region.localizedName', () {
    const czechia = Region(
      id: 2,
      parentId: null,
      name: 'Česko',
      nameEn: 'Czechia',
      namePl: 'Czechy',
      type: RegionType.country,
      code: 'CZ',
      totalAreaKm2: 78871,
      minLat: 48.5,
      maxLat: 51.1,
      minLon: 12.1,
      maxLon: 18.9,
    );

    test('Polish shows the Polish name', () {
      expect(czechia.localizedName('pl'), 'Czechy');
    });

    test('English shows the English name', () {
      expect(czechia.localizedName('en'), 'Czechia');
    });

    test('a language without a translation shows the local name', () {
      expect(czechia.localizedName('de'), 'Česko');
    });
  });
}
