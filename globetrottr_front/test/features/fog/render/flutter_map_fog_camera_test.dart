import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/adapters/flutter_map_fog_camera.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_test_helpers.dart';

MapCamera _mapCamera({
  required LatLng center,
  required double zoom,
  double rotation = 0,
  math.Point<double> size = const math.Point<double>(400, 800),
}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: center,
    zoom: zoom,
    rotation: rotation,
    nonRotatedSize: size,
  );
}

/// Cameras that differ in everything the projection depends on. The odd sizes
/// and zooms leave a fraction of a pixel that the map rounds away.
final List<MapCamera> _cameras = [
  _mapCamera(center: const LatLng(krakowLat, krakowLng), zoom: 16),
  _mapCamera(center: const LatLng(krakowLat, krakowLng), zoom: 17.37),
  _mapCamera(
    center: const LatLng(krakowLat, krakowLng),
    zoom: 15.5,
    rotation: 37,
  ),
  _mapCamera(
    center: const LatLng(-33.8688, 151.2093),
    zoom: 12.81,
    rotation: -120,
    size: const math.Point<double>(411, 799.5),
  ),
  _mapCamera(center: const LatLng(78.2232, 15.6267), zoom: 9.2, rotation: 90),
  _mapCamera(center: const LatLng(0.0001, -0.0001), zoom: 4.3),
];

/// Places around the center of [camera]: the center itself, points a few
/// hundred meters and a few kilometers away, and a corner of a fog tile.
List<LatLng> _placesAround(MapCamera camera) {
  final lat = camera.center.latitude;
  final lng = camera.center.longitude;
  final near = offsetMeters(lat, lng, north: 300, east: -150);
  final far = offsetMeters(lat, lng, north: -2500, east: 4000);
  final tileX = FogMercator.lngToX(lng, 15) ~/ FogTileId.size;
  final tileY = FogMercator.latToY(lat, 15) ~/ FogTileId.size;
  return [
    camera.center,
    LatLng(near.lat, near.lng),
    LatLng(far.lat, far.lng),
    LatLng(
      FogMercator.yToLat(tileY * FogTileId.size + 0.0, 15),
      FogMercator.xToLng(tileX * FogTileId.size + 0.0, 15),
    ),
  ];
}

void main() {
  group('toFogCamera', () {
    test('keeps the zoom, the rotation and the size of the map', () {
      final camera = _cameras[3];
      final fog = camera.toFogCamera();

      expect(fog.zoom, camera.zoom);
      expect(fog.rotation, camera.rotation);
      expect(fog.size, const Size(411, 799.5));
    });

    test('puts every place on the same pixel as the map', () {
      for (final camera in _cameras) {
        final fog = camera.toFogCamera();
        for (final place in _placesAround(camera)) {
          final expected = camera.latLngToScreenPoint(place);
          final actual = fog.toScreen(place);

          expect(
            actual.dx,
            closeTo(expected.x, 1e-6),
            reason: '$place on $fog',
          );
          expect(
            actual.dy,
            closeTo(expected.y, 1e-6),
            reason: '$place on $fog',
          );
        }
      }
    });

    test('the visible tiles hold every corner of the map', () {
      for (final camera in _cameras) {
        final fog = camera.toFogCamera();
        final z = camera.zoom.round();
        final range = fog.visibleTiles(z);
        final size = camera.nonRotatedSize;
        for (final corner in [
          const math.Point<double>(0, 0),
          math.Point<double>(size.x, 0),
          math.Point<double>(0, size.y),
          math.Point<double>(size.x, size.y),
        ]) {
          final place = camera.pointToLatLng(corner);

          expect(
            range.contains(tileOf(place.latitude, place.longitude, z)),
            isTrue,
            reason: 'corner $corner of $fog is outside $range',
          );
        }
      }
    });

    test('a camera that is not laid out yet is not usable', () {
      final camera = _mapCamera(
        center: const LatLng(krakowLat, krakowLng),
        zoom: 16,
        size: const math.Point<double>(-1, -1),
      );

      expect(camera.toFogCamera().isUsable, isFalse);
    });

    test('converting a camera with NaN values does not throw', () {
      for (final camera in [
        _mapCamera(center: const LatLng(double.nan, krakowLng), zoom: 16),
        _mapCamera(
          center: const LatLng(krakowLat, krakowLng),
          zoom: double.nan,
        ),
      ]) {
        expect(camera.toFogCamera().isUsable, isFalse);
      }
    });
  });
}
