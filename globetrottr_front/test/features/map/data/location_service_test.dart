import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

void main() {
  group('LocationService recording sessions', () {
    late LocationService service;

    setUp(() {
      service = LocationService(MapStorage(), InMemoryTrackLogStorage());
    });

    test('has no session before recording starts', () {
      expect(service.sessionId, isNull);
    });

    test('starts a session when recording is enabled', () {
      service.setRecording(true);

      expect(service.sessionId, isNotNull);
    });

    test('keeps the same session while recording stays enabled', () {
      service.setRecording(true);
      final first = service.sessionId;

      service.setRecording(true);

      expect(service.sessionId, first);
    });

    test('ends the session when recording is paused', () {
      service.setRecording(true);

      service.setRecording(false);

      expect(service.sessionId, isNull);
    });

    test('resuming after a pause starts a different session', () async {
      service.setRecording(true);
      final first = service.sessionId;
      service.setRecording(false);
      await Future<void>.delayed(const Duration(milliseconds: 2));

      service.setRecording(true);

      expect(service.sessionId, isNotNull);
      expect(service.sessionId, isNot(first));
    });
  });

  group('LocationService.isUsablePosition', () {
    Position at(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.utc(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test('accepts ordinary coordinates', () {
      expect(LocationService.isUsablePosition(at(50.06, 19.94)), isTrue);
      expect(LocationService.isUsablePosition(at(-90, 180)), isTrue);
    });

    test('rejects NaN, infinite and out of range coordinates', () {
      expect(LocationService.isUsablePosition(at(double.nan, 19)), isFalse);
      expect(LocationService.isUsablePosition(at(50, double.nan)), isFalse);
      expect(
        LocationService.isUsablePosition(at(double.infinity, 19)),
        isFalse,
      );
      expect(LocationService.isUsablePosition(at(91, 19)), isFalse);
      expect(LocationService.isUsablePosition(at(50, -181)), isFalse);
    });
  });
}
