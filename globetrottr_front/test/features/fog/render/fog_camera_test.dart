import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_test_helpers.dart';

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
  group('visibleTiles', () {
    test('covers the corners of the screen', () {
      final camera = _camera();
      final range = camera.visibleTiles(16);

      for (final corner in [
        camera.pointToLatLng(const math.Point<double>(0, 0)),
        camera.pointToLatLng(const math.Point<double>(400, 0)),
        camera.pointToLatLng(const math.Point<double>(0, 800)),
        camera.pointToLatLng(const math.Point<double>(400, 800)),
      ]) {
        expect(
          range.contains(
            tileOf(corner.latitude, corner.longitude, 16),
          ),
          isTrue,
          reason: '$corner',
        );
      }
    });

    test('is small enough to draw', () {
      final range = _camera().visibleTiles(16);

      expect(range.cellCount, lessThanOrEqualTo(12));
    });

    test('a rotated camera still covers the whole screen', () {
      final camera = _camera(rotation: 37);
      final range = camera.visibleTiles(16);

      for (final corner in [
        camera.pointToLatLng(const math.Point<double>(0, 0)),
        camera.pointToLatLng(const math.Point<double>(400, 0)),
        camera.pointToLatLng(const math.Point<double>(0, 800)),
        camera.pointToLatLng(const math.Point<double>(400, 800)),
      ]) {
        expect(
          range.contains(
            tileOf(corner.latitude, corner.longitude, 16),
          ),
          isTrue,
          reason: '$corner',
        );
      }
    });

    test('a country sized view needs only a few coarse tiles', () {
      final camera = _camera(zoom: 5.7, center: const LatLng(52, 19));
      final range = camera.visibleTiles(6);

      expect(range.cellCount, lessThanOrEqualTo(24));
    });
  });
}
