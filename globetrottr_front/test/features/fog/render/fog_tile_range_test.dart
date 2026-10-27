import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_range.dart';
import 'package:latlong2/latlong.dart';

MapCamera _camera({
  double zoom = 16,
  double rotation = 0,
  LatLng center = const LatLng(50.0614, 19.9383),
}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: center,
    zoom: zoom,
    rotation: rotation,
    nonRotatedSize: const math.Point<double>(400, 800),
  );
}

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

    test('visible range covers the corners of the screen', () {
      final camera = _camera();
      final range = FogTileRange.visible(camera, 16);

      for (final corner in [
        camera.pointToLatLng(const math.Point<double>(0, 0)),
        camera.pointToLatLng(const math.Point<double>(400, 0)),
        camera.pointToLatLng(const math.Point<double>(0, 800)),
        camera.pointToLatLng(const math.Point<double>(400, 800)),
      ]) {
        expect(
          range.contains(
            FogMercator.tileAt(corner.latitude, corner.longitude, 16),
          ),
          isTrue,
          reason: '$corner',
        );
      }
    });

    test('visible range is small enough to draw', () {
      final range = FogTileRange.visible(_camera(), 16);

      expect(range.cellCount, lessThanOrEqualTo(12));
    });

    test('a rotated camera still covers the whole screen', () {
      final camera = _camera(rotation: 37);
      final range = FogTileRange.visible(camera, 16);

      for (final corner in [
        camera.pointToLatLng(const math.Point<double>(0, 0)),
        camera.pointToLatLng(const math.Point<double>(400, 0)),
        camera.pointToLatLng(const math.Point<double>(0, 800)),
        camera.pointToLatLng(const math.Point<double>(400, 800)),
      ]) {
        expect(
          range.contains(
            FogMercator.tileAt(corner.latitude, corner.longitude, 16),
          ),
          isTrue,
          reason: '$corner',
        );
      }
    });

    test('a country sized view needs only a few coarse tiles', () {
      final camera = _camera(zoom: 5.7, center: const LatLng(52, 19));
      final range = FogTileRange.visible(camera, 6);

      expect(range.cellCount, lessThanOrEqualTo(24));
    });
  });
}
