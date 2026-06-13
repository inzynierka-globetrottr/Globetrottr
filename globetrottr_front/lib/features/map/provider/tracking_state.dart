import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final List<LatLng> discoveredPoints;
  final String? errorMessage;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.discoveredPoints = const [],
    this.errorMessage,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    List<LatLng>? discoveredPoints,
    String? errorMessage,
  }) => TrackingState(
    isTracking: isTracking ?? this.isTracking,
    isRecording: isRecording ?? this.isRecording,
    currentPosition: currentPosition ?? this.currentPosition,
    discoveredPoints: discoveredPoints ?? this.discoveredPoints,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
