import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final String? errorMessage;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.errorMessage,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
