import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

import '../../../support/fog_test_helpers.dart';

void main() {
  group('FogMercator', () {
    test('world size doubles with every zoom level', () {
      expect(FogMercator.worldSize(0), 256);
      expect(FogMercator.worldSize(1), 512);
      expect(FogMercator.worldSize(17), 256 * 131072);
    });

    test('maps the equator and prime meridian to the world center', () {
      expect(FogMercator.lngToX(0, 1), closeTo(256, 1e-9));
      expect(FogMercator.latToY(0, 1), closeTo(256, 1e-9));
    });

    test('maps the antimeridian and the Mercator limit to the world edge', () {
      expect(FogMercator.lngToX(-180, 5), closeTo(0, 1e-9));
      expect(FogMercator.lngToX(180, 5), closeTo(256 * 32, 1e-9));
      expect(
        FogMercator.latToY(FogMercator.maxLatitude, 5),
        closeTo(0, 1e-6),
      );
    });

    test('round-trips coordinates through world pixels', () {
      for (final lat in [-80.0, -33.3, 0.0, 19.9, 50.0614, 84.0]) {
        for (final lng in [-179.0, -45.5, 0.0, 19.9383, 179.0]) {
          final x = FogMercator.lngToX(lng, 17);
          final y = FogMercator.latToY(lat, 17);

          expect(FogMercator.xToLng(x, 17), closeTo(lng, 1e-9));
          expect(FogMercator.yToLat(y, 17), closeTo(lat, 1e-9));
        }
      }
    });

    test('finds the tile containing a coordinate', () {
      expect(tileOf(50, 19, 1), const FogTileId(1, 1, 0));
      expect(tileOf(-50, -19, 1), const FogTileId(1, 0, 1));
      expect(tileOf(0.0001, 0.0001, 1), const FogTileId(1, 1, 0));
    });

    test('finds the well-known OSM tile for London at zoom 10', () {
      final tile = tileOf(51.5074, -0.1278, 10);

      expect(tile, const FogTileId(10, 511, 340));
    });

    test('clamps latitudes beyond the Mercator limit', () {
      expect(FogMercator.latToY(90, 3), closeTo(0, 1e-6));
      expect(FogMercator.latToY(-90, 3), closeTo(256 * 8, 1e-6));
    });
  });

  group('FogTileId', () {
    test('equality and hash code depend on z, x and y', () {
      expect(const FogTileId(3, 2, 1), const FogTileId(3, 2, 1));
      expect(
        const FogTileId(3, 2, 1).hashCode,
        const FogTileId(3, 2, 1).hashCode,
      );
      expect(const FogTileId(3, 2, 1), isNot(const FogTileId(3, 1, 2)));
      expect(const FogTileId(3, 2, 1), isNot(const FogTileId(4, 2, 1)));
    });

    test('the ancestor one level up halves the coordinates', () {
      expect(const FogTileId(5, 13, 7).ancestorAt(4), const FogTileId(4, 6, 3));
    });

    test('ancestorAt walks up several levels', () {
      expect(
        const FogTileId(17, 72793, 44421).ancestorAt(14),
        const FogTileId(14, 9099, 5552),
      );
      expect(
        const FogTileId(6, 3, 2).ancestorAt(6),
        const FogTileId(6, 3, 2),
      );
    });

    test('key is unique for different tiles', () {
      final keys = <int>{};
      for (var z = 0; z < 4; z++) {
        for (var x = 0; x < (1 << z); x++) {
          for (var y = 0; y < (1 << z); y++) {
            keys.add(FogTileId(z, x, y).key);
          }
        }
      }

      expect(keys.length, 1 + 4 + 16 + 64);
    });

    test('fromKey restores the tile', () {
      const id = FogTileId(17, 72793, 44421);

      expect(FogTileId.fromKey(id.key), id);
    });
  });
}
