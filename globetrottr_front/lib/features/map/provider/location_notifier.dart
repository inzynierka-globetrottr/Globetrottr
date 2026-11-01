import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:latlong2/latlong.dart';

class LocationNotifier extends Notifier<TrackingState> {
  late LocationService _locationService;
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    _locationService = ref.read(locationServiceProvider);

    ref.onDispose(() {
      _positionStream?.cancel();
      _locationService.stopTracking();
    });

    return const TrackingState();
  }

  Future<void> startTracking() async {
    try {
      await _locationService.startTracking();
      unawaited(_positionStream?.cancel());
      _positionStream = _locationService.positionStream.listen(_onPosition);
      state = state.copyWith(isTracking: true, clearError: true);
    } catch (e) {
      state = state.copyWith(isTracking: false, errorMessage: e.toString());
    }
  }

  Future<void> setRecording(bool value) async {
    _locationService.setRecording(value);
    state = state.copyWith(isRecording: value);

    if (!value) {
      await ref.read(syncServiceProvider).syncPendingPoints();
    }
  }

  void _onPosition(Position position) {
    state = state.copyWith(
      currentPosition: LatLng(position.latitude, position.longitude),
    );
  }
}
