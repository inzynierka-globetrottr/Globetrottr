import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:latlong2/latlong.dart';

class FakeLocationService extends Fake implements LocationService {
  final StreamController<Position> controller =
      StreamController<Position>.broadcast();
  String? _sessionId;
  int _sessionCounter = 0;

  @override
  String? get sessionId => _sessionId;

  @override
  Stream<Position> get positionStream => controller.stream;

  @override
  Future<void> startTracking() async {}

  @override
  void stopTracking() {
    _sessionId = null;
  }

  @override
  void setRecording(bool value) {
    if (!value) {
      _sessionId = null;
    } else {
      _sessionId ??= 'session_${++_sessionCounter}';
    }
  }

  void emit(double latitude, double longitude) {
    controller.add(
      Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
  }
}

class FakeMapStorage extends Fake implements MapStorage {
  FakeMapStorage(this.pending);

  final List<PendingPoint> pending;

  @override
  Future<List<PendingPoint>> getPendingPoints() async => pending;
}

class FakeFogService extends Fake implements FogService {
  List<List<LatLng>> fog = const [];

  @override
  Future<List<List<LatLng>>> getMyFog() async => fog;
}

class FakeSyncService extends Fake implements SyncService {
  bool succeeds = true;

  @override
  Future<bool> syncPendingPoints() async => succeeds;
}

PendingPoint _pending(String session, int timestamp, double lat, double lng) {
  return PendingPoint(
    sessionId: session,
    latitude: lat,
    longitude: lng,
    timestamp: timestamp,
  );
}

void main() {
  late FakeLocationService locationService;
  late FakeFogService fogService;
  late FakeSyncService syncService;

  ProviderContainer createContainer({List<PendingPoint> pending = const []}) {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(locationService),
        mapStorageProvider.overrideWithValue(FakeMapStorage(pending)),
        fogServiceProvider.overrideWithValue(fogService),
        syncServiceProvider.overrideWithValue(syncService),
      ],
    );
    addTearDown(container.dispose);
    container.listen(locationProvider, (_, _) {});
    return container;
  }

  setUp(() {
    locationService = FakeLocationService();
    fogService = FakeFogService();
    syncService = FakeSyncService();
  });

  tearDown(() => locationService.controller.close());

  group('LocationNotifier fog tracks', () {
    test('loads unsynced points as one track per session', () async {
      final container = createContainer(
        pending: [
          _pending('a', 1, 50.0, 19.0),
          _pending('b', 2, 51.0, 20.0),
          _pending('a', 3, 50.1, 19.1),
        ],
      );

      await pumpEventQueue();

      final tracks = container.read(locationProvider).sessionTracks;
      expect(tracks.map((t) => t.sessionId), ['a', 'b']);
      expect(tracks.first.points.length, 2);
    });

    test('keeps backend fog separate from session tracks', () async {
      fogService.fog = [
        [const LatLng(50, 19), const LatLng(50, 19.1), const LatLng(50.1, 19)],
      ];
      final container = createContainer();

      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.backendHoles.length, 1);
      expect(state.sessionTracks, isEmpty);
    });

    test('does not add tracks while not recording', () async {
      final container = createContainer();
      await pumpEventQueue();
      await container.read(locationProvider.notifier).startTracking();

      locationService.emit(50.0, 19.0);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.currentPosition, const LatLng(50.0, 19.0));
      expect(state.sessionTracks, isEmpty);
    });

    test('appends recorded positions to a single track', () async {
      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      await notifier.setRecording(true);

      locationService.emit(50.0, 19.0);
      locationService.emit(50.1, 19.1);
      locationService.emit(50.2, 19.2);
      await pumpEventQueue();

      final tracks = container.read(locationProvider).sessionTracks;
      expect(tracks.length, 1);
      expect(tracks.single.points, [
        const LatLng(50.0, 19.0),
        const LatLng(50.1, 19.1),
        const LatLng(50.2, 19.2),
      ]);
    });

    test('resuming after a pause starts a new track', () async {
      syncService.succeeds = false;
      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();

      await notifier.setRecording(true);
      locationService.emit(50.0, 19.0);
      await pumpEventQueue();
      await notifier.setRecording(false);
      await notifier.setRecording(true);
      locationService.emit(52.0, 21.0);
      await pumpEventQueue();

      final tracks = container.read(locationProvider).sessionTracks;
      expect(tracks.length, 2);
      expect(tracks[0].points, [const LatLng(50.0, 19.0)]);
      expect(tracks[1].points, [const LatLng(52.0, 21.0)]);
    });

    test('clears tracks and refreshes backend fog after a sync', () async {
      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      await notifier.setRecording(true);
      locationService.emit(50.0, 19.0);
      await pumpEventQueue();
      fogService.fog = [
        [const LatLng(50, 19), const LatLng(50, 19.1), const LatLng(50.1, 19)],
      ];

      await notifier.setRecording(false);

      final state = container.read(locationProvider);
      expect(state.sessionTracks, isEmpty);
      expect(state.backendHoles.length, 1);
    });

    test('keeps tracks when the sync fails', () async {
      syncService.succeeds = false;
      final container = createContainer();
      await pumpEventQueue();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      await notifier.setRecording(true);
      locationService.emit(50.0, 19.0);
      await pumpEventQueue();

      await notifier.setRecording(false);

      expect(container.read(locationProvider).sessionTracks.length, 1);
    });
  });
}
