import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/location_service.dart';
import '../data/map_storage.dart';
import 'tracking_state.dart';
import '../../fog/fog_holepuncher.dart';
import '../../../core/config/map_config.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';

class LocationNotifier extends Notifier<TrackingState> {
  late final LocationService _locationService;
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    _locationService = LocationService();
    Future.microtask(() => _initializeHistoryFromDb());
    return const TrackingState();
  }

  //Load previously recorded points from the database and compute initial holes for the fog layer.
  Future<void> _initializeHistoryFromDb() async {
    final pendingPoints = await MapStorage().getPendingPoints();

    final latLngPoints = pendingPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    _processAndSetInitialState(latLngPoints);
  }

  // Convert raw LatLng points into hole coordinates and update the state with both discovered points and their corresponding holes.
  void _processAndSetInitialState(List<LatLng> points) {
    final initialHoles = points.map((point) {
      return FogHolepuncher.calculateSingleHole(
        center: point,
        radiusInMeters: MapConfig.defaultVisionRadius,
      );
    }).toList();

    state = state.copyWith(
      calculatedHoles: initialHoles,
      holesRevision: state.holesRevision + 1
    );
  }

  Future<void> startTracking() async {
    try {
      await _locationService.startTracking();
      _positionStream = _locationService.positionStream.listen(_onPosition);
      state = state.copyWith(isTracking: true, errorMessage: null);
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
    state = state.copyWith(isRecording: value, errorMessage: null);

    if (!value) {
      final token = await AuthService().getToken();
      if (token != null) {
        await SyncService().syncPendingPoints(token);
      }
    }
  }

  void _onPosition(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);

    List<List<LatLng>> updatedHoles = state.calculatedHoles;

    if (state.isRecording) {
      //Optimized calculation: Instead of recalculating holes for all points, we only calculate a new hole
      final newHoleGeometry = FogHolepuncher.calculateSingleHole(
        center: newPosition,
        radiusInMeters: MapConfig.defaultVisionRadius,
      );

      updatedHoles = List.from(state.calculatedHoles)..add(newHoleGeometry);
    }

    state = state.copyWith(
      currentPosition: newPosition,
      calculatedHoles: updatedHoles,
      holesRevision: state.isRecording
        ? state.holesRevision + 1
        : state.holesRevision,
    );
  }
}
