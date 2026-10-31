import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';

import '../../../support/in_memory_track_log_storage.dart';

class _GatedMapStorage extends MapStorage {
  final Completer<int> gate = Completer<int>();
  final List<PendingPoint> inserted = [];

  @override
  Future<int> insertPendingPoint(PendingPoint point) async {
    inserted.add(point);
    return gate.future;
  }
}

class _FailingMapStorage extends MapStorage {
  @override
  Future<int> insertPendingPoint(PendingPoint point) async {
    throw StateError('database is locked');
  }
}

Position _at(double lat, double lng) => Position(
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

void main() {
  group('LocationService.recordPosition', () {
    test(
      'keeps a fix whose recording stopped while it was being stored',
      () async {
        final mapStorage = _GatedMapStorage();
        final trackLog = InMemoryTrackLogStorage();
        final service = LocationService(mapStorage, trackLog);
        service.setRecording(true);
        final session = service.sessionId;

        final recorded = service.recordPosition(_at(50.06, 19.94));
        service.setRecording(false);
        mapStorage.gate.complete(1);
        await recorded;

        final logged = await trackLog.entriesAfter(0);
        expect(logged, hasLength(1));
        expect(logged.single.sessionId, session);
        expect(mapStorage.inserted.single.sessionId, session);
      },
    );

    test('stores the fix time, not the writing time, in both places', () async {
      final mapStorage = _GatedMapStorage()..gate.complete(1);
      final trackLog = InMemoryTrackLogStorage();
      final service = LocationService(mapStorage, trackLog);
      service.setRecording(true);

      await service.recordPosition(_at(50.06, 19.94));

      final fixTime = DateTime.utc(2026).millisecondsSinceEpoch;
      expect(mapStorage.inserted.single.timestamp, fixTime);
      expect((await trackLog.entriesAfter(0)).single.timestampMs, fixTime);
    });

    test('ignores a fix that arrives while not recording', () async {
      final mapStorage = _GatedMapStorage();
      final trackLog = InMemoryTrackLogStorage();
      final service = LocationService(mapStorage, trackLog);

      await service.recordPosition(_at(50.06, 19.94));

      expect(mapStorage.inserted, isEmpty);
      expect(await trackLog.count(), 0);
    });

    test('still logs the fix when the pending point write fails', () async {
      final trackLog = InMemoryTrackLogStorage();
      final service = LocationService(_FailingMapStorage(), trackLog);
      service.setRecording(true);
      final emitted = service.loggedPoints.first;

      await service.recordPosition(_at(50.06, 19.94));

      expect(await trackLog.count(), 1);
      expect((await emitted).sessionId, service.sessionId);
    });
  });

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
    test('accepts ordinary coordinates', () {
      expect(LocationService.isUsablePosition(_at(50.06, 19.94)), isTrue);
      expect(LocationService.isUsablePosition(_at(-90, 180)), isTrue);
    });

    test('rejects NaN, infinite and out of range coordinates', () {
      expect(LocationService.isUsablePosition(_at(double.nan, 19)), isFalse);
      expect(LocationService.isUsablePosition(_at(50, double.nan)), isFalse);
      expect(
        LocationService.isUsablePosition(_at(double.infinity, 19)),
        isFalse,
      );
      expect(LocationService.isUsablePosition(_at(91, 19)), isFalse);
      expect(LocationService.isUsablePosition(_at(50, -181)), isFalse);
    });
  });
}
