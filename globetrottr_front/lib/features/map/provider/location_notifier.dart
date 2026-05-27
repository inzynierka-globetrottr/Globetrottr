import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/location_service.dart';
import 'tracking_state.dart';

class LocationNotifier extends Notifier<TrackingState> {
  late final LocationService _locationService;
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    _locationService = LocationService();
    return const TrackingState();
  }

  Future<void> startTracking() async {
    try {
      await _locationService.startTracking();
      _positionStream = _locationService.positionStream.listen(_onPosition);
      state = state.copyWith(isTracking: true, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isTracking: false,
        errorMessage: e.toString(),
      );
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
    state = state.copyWith(
      currentPosition: LatLng(position.latitude, position.longitude),
    );
  }
}
