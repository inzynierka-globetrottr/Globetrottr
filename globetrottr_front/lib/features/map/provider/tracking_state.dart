import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final List<LatLng> discoveredPoints;
  final List<List<LatLng>> calculatedHoles;
  final String? errorMessage;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.discoveredPoints = const [],
    this.calculatedHoles = const [],
    this.errorMessage,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    List<LatLng>? discoveredPoints,
    List<List<LatLng>>? calculatedHoles,
    String? errorMessage,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      discoveredPoints: discoveredPoints ?? this.discoveredPoints,
      calculatedHoles: calculatedHoles ?? this.calculatedHoles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
