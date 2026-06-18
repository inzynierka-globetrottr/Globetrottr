import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final List<List<LatLng>> calculatedHoles;
  final String? errorMessage;
  final int holesRevision;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.calculatedHoles = const [],
    this.errorMessage,
    this.holesRevision = 0
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    List<List<LatLng>>? calculatedHoles,
    String? errorMessage,
    int? holesRevision
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      calculatedHoles: calculatedHoles ?? this.calculatedHoles,
      errorMessage: errorMessage ?? this.errorMessage,
      holesRevision: holesRevision ?? this.holesRevision
    );
  }
}
