import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/location_service.dart';
import '../data/map_storage.dart';
import 'tracking_state.dart';

class LocationNotifier extends Notifier<TrackingState> {
  late final LocationService _locationService;
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    _locationService = LocationService();
    Future.microtask(() => _loadPointsFromDb());
    return const TrackingState();
  }

  Future<void> _loadPointsFromDb() async {
    final pendingPoints = await MapStorage().getPendingPoints();
    final latLngPoints = pendingPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    state = state.copyWith(discoveredPoints: latLngPoints);
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

  void setRecording(bool value) {
    _locationService.setRecording(value);
    state = state.copyWith(isRecording: value);
  }

  void _onPosition(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);
    List<LatLng> updatedPoints = state.discoveredPoints;

    if (state.isRecording) {
      updatedPoints = List.from(state.discoveredPoints)..add(newPosition);
    }

    state = state.copyWith(
      currentPosition: newPosition,
      discoveredPoints: updatedPoints,
    );
  }
}
