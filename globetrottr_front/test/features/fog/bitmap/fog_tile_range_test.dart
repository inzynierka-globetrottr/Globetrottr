import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';

void main() {
  group('FogTileRange', () {
    test('lists its tiles row by row', () {
      const range = FogTileRange(z: 5, xMin: 2, xMax: 3, yMin: 7, yMax: 8);

      expect(range.cellCount, 4);
      expect(range.ids.toList(), [
        const FogTileId(5, 2, 7),
        const FogTileId(5, 3, 7),
        const FogTileId(5, 2, 8),
        const FogTileId(5, 3, 8),
      ]);
    });

    test('contains only tiles inside the range', () {
      const range = FogTileRange(z: 5, xMin: 2, xMax: 3, yMin: 7, yMax: 8);

      expect(range.contains(const FogTileId(5, 3, 8)), isTrue);
      expect(range.contains(const FogTileId(5, 4, 8)), isFalse);
      expect(range.contains(const FogTileId(6, 3, 8)), isFalse);
    });

    test('expand grows on every side and stays inside the world', () {
      const range = FogTileRange(z: 2, xMin: 0, xMax: 1, yMin: 3, yMax: 3);

      final grown = range.expand(1);

      expect(grown.xMin, 0);
      expect(grown.xMax, 2);
      expect(grown.yMin, 2);
      expect(grown.yMax, 3);
    });

    test('equal ranges compare equal', () {
      const a = FogTileRange(z: 5, xMin: 1, xMax: 2, yMin: 3, yMax: 4);
      const b = FogTileRange(z: 5, xMin: 1, xMax: 2, yMin: 3, yMax: 4);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('covering finds the tiles under a box of pixels', () {
      final range = FogTileRange.covering(
        z: 5,
        minX: 255,
        maxX: 256,
        minY: 512,
        maxY: 767.5,
      );

      expect(
        range,
        const FogTileRange(z: 5, xMin: 0, xMax: 1, yMin: 2, yMax: 2),
      );
    });

    test('covering cuts a box to the world', () {
      final range = FogTileRange.covering(
        z: 1,
        minX: -50,
        maxX: 9000,
        minY: -1,
        maxY: 10,
      );

      expect(
        range,
        const FogTileRange(z: 1, xMin: 0, xMax: 1, yMin: 0, yMax: 0),
      );
    });
  });
}
