import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/finite_camera_constraint.dart';
import 'package:latlong2/latlong.dart';

MapCamera _camera({LatLng center = const LatLng(50, 20), double zoom = 16}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: center,
    zoom: zoom,
    rotation: 0,
    nonRotatedSize: const math.Point<double>(400, 800),
  );
}

void main() {
  const constraint = FiniteCameraConstraint();

  group('FiniteCameraConstraint', () {
    test('keeps a finite camera as it is', () {
      final camera = _camera();

      expect(constraint.constrain(camera), same(camera));
    });

    test('rejects a NaN center', () {
      expect(
        constraint.constrain(_camera(center: const LatLng(double.nan, 20))),
        isNull,
      );
      expect(
        constraint.constrain(_camera(center: const LatLng(50, double.nan))),
        isNull,
      );
    });

    test('rejects an infinite or NaN zoom', () {
      expect(constraint.constrain(_camera(zoom: double.infinity)), isNull);
      expect(
        constraint.constrain(_camera(zoom: double.negativeInfinity)),
        isNull,
      );
      expect(constraint.constrain(_camera(zoom: double.nan)), isNull);
    });
  });

  testWidgets('a map with the constraint ignores a move to a broken camera', (
    tester,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          mapController: controller,
          options: const MapOptions(
            initialCenter: LatLng(50, 20),
            initialZoom: 16,
            cameraConstraint: FiniteCameraConstraint(),
          ),
          children: const [],
        ),
      ),
    );

    final moved = controller.move(
      const LatLng(double.nan, double.nan),
      double.infinity,
    );
    await tester.pump();

    expect(moved, isFalse);
    expect(controller.camera.center, const LatLng(50, 20));
    expect(controller.camera.zoom, 16);
  });
}
