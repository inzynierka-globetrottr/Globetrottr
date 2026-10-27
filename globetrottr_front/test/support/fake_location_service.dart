import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

class FakeLocationService extends Fake implements LocationService {
  final StreamController<Position> positions =
      StreamController<Position>.broadcast();
  final StreamController<TrackLogEntry> logged =
      StreamController<TrackLogEntry>.broadcast();
  String? _sessionId;
  int _sessionCounter = 0;
  Exception? startError;

  @override
  String? get sessionId => _sessionId;

  @override
  Stream<Position> get positionStream => positions.stream;

  @override
  Stream<TrackLogEntry> get loggedPoints => logged.stream;

  @override
  Future<void> startTracking() async {
    if (startError != null) throw startError!;
  }

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
    positions.add(
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

class FakeSyncService extends Fake implements SyncService {
  bool succeeds = true;
  int calls = 0;

  @override
  Future<bool> syncPendingPoints() async {
    calls++;
    return succeeds;
  }
}

class FogTestEnvironment {
  FogTestEnvironment({
    FakeLocationService? location,
    FakeSyncService? sync,
    InMemoryTrackLogStorage? log,
    InMemoryFogTileStorage? tiles,
  }) : location = location ?? FakeLocationService(),
       sync = sync ?? FakeSyncService(),
       log = log ?? InMemoryTrackLogStorage(),
       tiles = tiles ?? InMemoryFogTileStorage();

  final FakeLocationService location;
  final FakeSyncService sync;
  final InMemoryTrackLogStorage log;
  final InMemoryFogTileStorage tiles;

  List<Override> get overrides => [
    locationServiceProvider.overrideWithValue(location),
    syncServiceProvider.overrideWithValue(sync),
    trackLogStorageProvider.overrideWithValue(log),
    fogTileStorageProvider.overrideWithValue(tiles),
  ];

  ProviderContainer createContainer() {
    final container = ProviderContainer(overrides: overrides);
    container.listen(locationProvider, (_, _) {});
    return container;
  }
}
