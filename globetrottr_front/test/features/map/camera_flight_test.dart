import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/camera_flight.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const from = (center: LatLng(50, 19), zoom: 14.0);
  const to = (center: LatLng(51, 21), zoom: 16.0);

  group('CameraFlight', () {
    test('starts at the current view and ends at the target', () {
      const flight = CameraFlight(from: from, to: to);

      expect(flight.at(0), from);
      expect(flight.at(1), to);
    });

    test('moves the centre and the zoom together', () {
      final halfway = const CameraFlight(from: from, to: to).at(0.5);

      expect(halfway.center.latitude, closeTo(50.5, 1e-9));
      expect(halfway.center.longitude, closeTo(20, 1e-9));
      expect(halfway.zoom, closeTo(15, 1e-9));
    });

    test('has nowhere to go when the camera is already there', () {
      expect(const CameraFlight(from: to, to: to).isStill, isTrue);
      expect(const CameraFlight(from: from, to: to).isStill, isFalse);
    });
  });

  group('a flight is interrupted', () {
    test('by the user grabbing the map', () {
      for (final source in [
        MapEventSource.dragStart,
        MapEventSource.multiFingerGestureStart,
        MapEventSource.doubleTap,
        MapEventSource.doubleTapHold,
        MapEventSource.scrollWheel,
      ]) {
        expect(interruptsCameraFlight(source), isTrue, reason: '$source');
      }
    });

    test('not by its own moves or a tap', () {
      expect(interruptsCameraFlight(MapEventSource.mapController), isFalse);
      expect(interruptsCameraFlight(MapEventSource.tap), isFalse);
    });
  });
}
