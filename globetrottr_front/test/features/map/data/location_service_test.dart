import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';

void main() {
  group('LocationService recording sessions', () {
    late LocationService service;

    setUp(() {
      service = LocationService(MapStorage());
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
}
