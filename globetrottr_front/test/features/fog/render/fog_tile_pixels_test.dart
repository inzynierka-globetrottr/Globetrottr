import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';

int _alpha(List<int> pixels, int x, int y) =>
    pixels[(y * FogTilePixels.side + x) * 4];

void main() {
  group('FogTilePixels.build', () {
    test('produces a padded RGBA buffer', () {
      final pixels = FogTilePixels.build(FogMask(), neighbor: (dx, dy) => null);

      expect(FogTilePixels.side, 258);
      expect(pixels.length, 258 * 258 * 4);
    });

    test('draws the coverage as opaque grey', () {
      final mask = FogMask()
        ..data[0] = 255
        ..data[FogMask.size * 5 + 7] = 100;

      final pixels = FogTilePixels.build(mask, neighbor: (dx, dy) => null);

      expect(_alpha(pixels, 1, 1), 255);
      expect(_alpha(pixels, 8, 6), 100);
      expect(_alpha(pixels, 100, 100), 0);
      for (var i = 0; i < pixels.length; i += 4) {
        expect(pixels[i + 1], pixels[i]);
        expect(pixels[i + 2], pixels[i]);
        expect(pixels[i + 3], 255);
      }
    });

    test('replicates the edge pixels when there are no neighbours', () {
      final mask = FogMask();
      mask.data[0] = 200;
      mask.data[FogMask.size - 1] = 150;
      mask.data[FogMask.size * (FogMask.size - 1)] = 90;
      mask.data[FogMask.pixels - 1] = 60;

      final pixels = FogTilePixels.build(mask, neighbor: (dx, dy) => null);

      expect(_alpha(pixels, 0, 0), 200);
      expect(_alpha(pixels, 1, 0), 200);
      expect(_alpha(pixels, 0, 1), 200);
      expect(_alpha(pixels, 257, 0), 150);
      expect(_alpha(pixels, 0, 257), 90);
      expect(_alpha(pixels, 257, 257), 60);
    });

    test('takes the margin from the neighbouring tiles', () {
      final west = FogMask();
      final east = FogMask();
      final north = FogMask();
      final northWest = FogMask();
      for (var i = 0; i < FogMask.size; i++) {
        west.data[i * FogMask.size + FogMask.size - 1] = 11;
        east.data[i * FogMask.size] = 22;
        north.data[(FogMask.size - 1) * FogMask.size + i] = 33;
      }
      northWest.data[FogMask.pixels - 1] = 44;

      FogMask? neighbor(int dx, int dy) {
        if (dx == -1 && dy == 0) return west;
        if (dx == 1 && dy == 0) return east;
        if (dx == 0 && dy == -1) return north;
        if (dx == -1 && dy == -1) return northWest;
        return null;
      }

      final pixels = FogTilePixels.build(FogMask(), neighbor: neighbor);

      expect(_alpha(pixels, 0, 100), 11);
      expect(_alpha(pixels, 257, 100), 22);
      expect(_alpha(pixels, 100, 0), 33);
      expect(_alpha(pixels, 0, 0), 44);
    });

    test('the interior is never taken from neighbours', () {
      final mask = FogMask()..data[FogMask.size + 1] = 77;
      final full = FogMask()..data.fillRange(0, FogMask.pixels, 255);

      final pixels = FogTilePixels.build(mask, neighbor: (dx, dy) => full);

      expect(_alpha(pixels, 2, 2), 77);
      expect(_alpha(pixels, 3, 3), 0);
    });
  });
}
