import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_test_helpers.dart';

const Size _screen = Size(400, 800);
const LatLng _krakow = LatLng(krakowLat, krakowLng);

FogCamera _camera({
  double zoom = 16,
  double rotation = 0,
  LatLng center = _krakow,
}) {
  return FogCamera(
    center: center,
    zoom: zoom,
    rotation: rotation,
    size: _screen,
  );
}

void _expectNear(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-6), reason: '$actual');
  expect(actual.dy, closeTo(expected.dy, 1e-6), reason: '$actual');
}

/// Whether [point] lies inside the outline of tile [id] on the screen. The
/// outline is convex, so the point is inside when it is on the same side of
/// all four edges.
bool _tileHolds(FogCamera camera, FogTileId id, Offset point) {
  const tile = FogTileId.size + 0.0;
  final x = id.x * tile;
  final y = id.y * tile;
  final corners = [
    camera.worldToScreen(x, y, id.z),
    camera.worldToScreen(x + tile, y, id.z),
    camera.worldToScreen(x + tile, y + tile, id.z),
    camera.worldToScreen(x, y + tile, id.z),
  ];
  var turn = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = corners[i];
    final b = corners[(i + 1) % 4];
    final cross =
        (b.dx - a.dx) * (point.dy - a.dy) - (b.dy - a.dy) * (point.dx - a.dx);
    if (cross == 0) continue;
    if (turn == 0) {
      turn = cross.sign;
    } else if (cross.sign != turn) {
      return false;
    }
  }
  return true;
}

void _expectCoversScreen(FogCamera camera, int z) {
  final range = camera.visibleTiles(z);
  for (final corner in [
    Offset.zero,
    Offset(_screen.width, 0),
    Offset(0, _screen.height),
    Offset(_screen.width, _screen.height),
  ]) {
    expect(
      range.ids.any((id) => _tileHolds(camera, id, corner)),
      isTrue,
      reason: 'corner $corner is outside $range',
    );
  }
}

void main() {
  group('toScreen', () {
    test('puts the center in the middle of the screen', () {
      for (final rotation in [0.0, 37.0]) {
        _expectNear(
          _camera(rotation: rotation).toScreen(_krakow),
          const Offset(200, 400),
        );
      }
    });

    test('agrees with world pixels of any level', () {
      final camera = _camera(zoom: 15.4, rotation: 20);
      final at = offsetMeters(krakowLat, krakowLng, north: 120, east: -80);

      _expectNear(
        camera.toScreen(LatLng(at.lat, at.lng)),
        camera.worldToScreen(
          FogMercator.lngToX(at.lng, 15),
          FogMercator.latToY(at.lat, 15),
          15,
        ),
      );
    });
  });

  group('worldToScreen', () {
    final x = FogMercator.lngToX(krakowLng, 16);
    final y = FogMercator.latToY(krakowLat, 16);

    test('a tile of the level that matches the zoom is 256 px wide', () {
      final camera = _camera();
      final step =
          camera.worldToScreen(x + 256, y, 16) - camera.worldToScreen(x, y, 16);

      _expectNear(step, const Offset(256, 0));
    });

    test('one zoom level more doubles the size of a tile', () {
      final camera = _camera(zoom: 17);
      final step =
          camera.worldToScreen(x + 256, y, 16) - camera.worldToScreen(x, y, 16);

      _expectNear(step, const Offset(512, 0));
    });

    test('a positive rotation turns the map clockwise', () {
      final camera = _camera(rotation: 90);
      final east =
          camera.worldToScreen(x + 256, y, 16) - camera.worldToScreen(x, y, 16);

      _expectNear(east, const Offset(0, 256));
    });
  });

  group('visibleTiles', () {
    test('covers the corners of the screen', () {
      _expectCoversScreen(_camera(), 16);
    });

    test('a rotated camera still covers the whole screen', () {
      _expectCoversScreen(_camera(rotation: 37), 16);
    });

    test('covers the screen with coarser tiles when zoomed in', () {
      _expectCoversScreen(_camera(zoom: 17.6), 15);
    });

    test('is small enough to draw', () {
      expect(_camera().visibleTiles(16).cellCount, lessThanOrEqualTo(12));
    });

    test('a country sized view needs only a few coarse tiles', () {
      final camera = _camera(zoom: 5.7, center: const LatLng(52, 19));

      expect(camera.visibleTiles(6).cellCount, lessThanOrEqualTo(24));
    });
  });

  group('equality', () {
    test('cameras with the same values are equal', () {
      expect(_camera(), _camera());
      expect(_camera().hashCode, _camera().hashCode);
    });

    test('any changed value makes a different camera', () {
      final base = _camera();

      expect(_camera(zoom: 16.01), isNot(base));
      expect(_camera(rotation: 1), isNot(base));
      expect(_camera(center: const LatLng(krakowLat, 19.94)), isNot(base));
      expect(
        FogCamera(center: _krakow, zoom: 16, size: const Size(400, 801)),
        isNot(base),
      );
    });
  });
}
