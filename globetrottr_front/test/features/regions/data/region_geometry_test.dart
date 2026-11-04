import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region_geometry.dart';

import '../../../support/region_geometry_encoder.dart';

/// A 1 x 1 degree square at 19-20 E, 50-51 N with a 0.2 degree hole in the
/// middle, as written by `tool/regions/build_regions.py`.
final _squareWithHole = Uint8List.fromList([
  0x02, 0x05, 0xc0, 0xf7, 0xe7, 0x01, 0x80, 0xad, 0xe2, 0x04, 0xc0, 0x9a, //
  0x0c, 0x00, 0x00, 0xc0, 0x9a, 0x0c, 0xbf, 0x9a, 0x0c, 0x00, 0x00, 0xbf,
  0x9a, 0x0c, 0x05, 0xc0, 0xe8, 0xec, 0x01, 0x80, 0x9e, 0xe7, 0x04, 0xc0,
  0xb8, 0x02, 0x00, 0x00, 0xc0, 0xb8, 0x02, 0xbf, 0xb8, 0x02, 0x00, 0x00,
  0xbf, 0xb8, 0x02,
]);

void main() {
  test('decodes the rings the build script writes', () {
    final rings = decodeRegionGeometry(_squareWithHole);

    expect(rings, hasLength(2));
    expect(rings[0], [
      (19.0, 50.0),
      (20.0, 50.0),
      (20.0, 51.0),
      (19.0, 51.0),
      (19.0, 50.0),
    ]);
    expect(rings[1].first, (19.4, 50.4));
  });

  test('a point inside the outer ring is inside', () {
    expect(regionGeometryContains(_squareWithHole, 50.2, 19.2), isTrue);
  });

  test('a point inside the hole is outside', () {
    expect(regionGeometryContains(_squareWithHole, 50.5, 19.5), isFalse);
  });

  test('a point beyond the square is outside', () {
    expect(regionGeometryContains(_squareWithHole, 50.5, 20.5), isFalse);
  });

  test('a ring of 70,000 points decodes completely', () {
    final ring = [
      for (var i = 0; i < 70000; i++) (19 + i * 1e-5, 50 + (i % 7) * 1e-5),
      (19.0, 50.0),
    ];

    final rings = decodeRegionGeometry(encodeRegionGeometry([ring]));

    expect(rings.single, hasLength(70001));
    expect(rings.single[69999].$1, closeTo(19.69999, 1e-9));
  });
}
