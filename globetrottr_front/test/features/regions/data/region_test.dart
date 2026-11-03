import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';

Uint8List _encodePolygon(List<List<List<double>>> rings) {
  final byteData = ByteData(
    2 +
        rings.fold<int>(
          0,
          (sum, r) => sum + 2 + r.length * 8,
        ),
  );
  var offset = 0;
  byteData.setUint16(offset, rings.length, Endian.little);
  offset += 2;
  for (final ring in rings) {
    byteData.setUint16(offset, ring.length, Endian.little);
    offset += 2;
    for (final pt in ring) {
      byteData.setFloat32(offset, pt[0], Endian.little);
      offset += 4;
      byteData.setFloat32(offset, pt[1], Endian.little);
      offset += 4;
    }
  }
  return byteData.buffer.asUint8List();
}

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
      final triangleGeom = _encodePolygon([
        [
          [10.0, 10.0],
          [20.0, 10.0],
          [10.0, 20.0],
          [10.0, 10.0],
        ],
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
}
