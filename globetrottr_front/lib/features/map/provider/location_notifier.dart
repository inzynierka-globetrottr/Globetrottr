import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/fog/fog_holepuncher.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';

class LocationNotifier extends Notifier<TrackingState> {
  late LocationService _locationService;
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    _locationService = ref.read(locationServiceProvider);
    Future.microtask(_initialize);

    ref.onDispose(() {
      _positionStream?.cancel();
      _locationService.stopTracking();
    });

    return const TrackingState();
  }

  Future<void> _initialize() async {
    await _fetchBackendFog();
    await _loadUnsyncedLocalPoints();
  }

  Future<void> _fetchBackendFog() async {
    try {
      final holes = await ref.read(fogServiceProvider).getMyFog();
      state = state.copyWith(
        backendHoles: holes,
        holesRevision: state.holesRevision + 1,
      );
    } catch (e) {
      print('Failed to fetch backend fog: $e');
    }
  }

  Future<void> _loadUnsyncedLocalPoints() async {
    try {
      final pending = await ref.read(mapStorageProvider).getPendingPoints();
      if (pending.isEmpty) return;

      final holes = pending
          .map(
            (p) => FogHolepuncher.calculateSingleHole(
              center: LatLng(p.latitude, p.longitude),
              radiusInMeters: MapConfig.defaultVisionRadius,
            ),
          )
          .toList();

      state = state.copyWith(
        sessionHoles: holes,
        holesRevision: state.holesRevision + 1,
      );
    } catch (e, stack) {
      print('Failed to load unsynced points from DB: $e\n$stack');
    }
  }

  Future<void> startTracking() async {
    try {
      await _locationService.startTracking();
      _positionStream = _locationService.positionStream.listen(_onPosition);
      state = state.copyWith(isTracking: true);
    } catch (e) {
      state = state.copyWith(isTracking: false, errorMessage: e.toString());
    }
  }

  void stopTracking() {
    _locationService.stopTracking();
    _positionStream?.cancel();
    _positionStream = null;
    state = state.copyWith(isTracking: false, isRecording: false);
  }

  Future<void> setRecording(bool value) async {
    _locationService.setRecording(value);
    state = state.copyWith(isRecording: value);

    if (!value) {
      await ref.read(syncServiceProvider).syncPendingPoints();

      try {
        final updatedHoles = await ref.read(fogServiceProvider).getMyFog();
        state = state.copyWith(
          backendHoles: updatedHoles,
          holesRevision: state.holesRevision + 1,
        );
      } catch (e) {
        print('Fog re-fetch after sync failed: $e');
      }
    }
  }

  void _onPosition(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);

    List<List<LatLng>> updatedHoles = state.sessionHoles;

    if (state.isRecording) {
      //Optimized calculation: Instead of recalculating holes for all points, we only calculate a new hole
      final newHoleGeometry = FogHolepuncher.calculateSingleHole(
        center: newPosition,
        radiusInMeters: MapConfig.defaultVisionRadius,
      );

      updatedHoles = List.from(state.sessionHoles)..add(newHoleGeometry);
    }

    state = state.copyWith(
      currentPosition: newPosition,
      sessionHoles: updatedHoles,
      holesRevision: state.isRecording
          ? state.holesRevision + 1
          : state.holesRevision,
    );
  }

  void reset() {
    state = const TrackingState();
  }
}
