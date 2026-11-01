import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/camera_health.dart';
import 'package:latlong2/latlong.dart';

MapCamera _camera({
  LatLng center = const LatLng(50, 20),
  double zoom = 16,
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

void main() {
  group('describeCameraProblem', () {
    test('is null for a healthy camera', () {
      expect(describeCameraProblem(_camera()), isNull);
    });

    test('names a non finite center', () {
      final text = describeCameraProblem(
        _camera(center: const LatLng(double.nan, 20)),
      );

      expect(text, contains('center'));
      expect(text, contains('NaN'));
    });

    test('names a non finite zoom', () {
      final text = describeCameraProblem(_camera(zoom: double.infinity));

      expect(text, contains('zoom'));
      expect(text, contains('Infinity'));
    });

    test('names a non finite rotation', () {
      expect(
        describeCameraProblem(_camera(rotation: double.nan)),
        contains('rotation'),
      );
    });

    test('names a map without a real size', () {
      expect(
        describeCameraProblem(_camera(size: const math.Point<double>(0, 0))),
        contains('size'),
      );
    });

    test('lists every problem at once', () {
      final text = describeCameraProblem(
        _camera(zoom: double.nan, rotation: double.infinity),
      );

      expect(text, allOf(contains('zoom'), contains('rotation')));
    });
  });
}
