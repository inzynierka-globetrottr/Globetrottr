import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final List<List<LatLng>> backendHoles;
  final List<List<LatLng>> sessionHoles;
  final String? errorMessage;
  final int holesRevision;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.backendHoles = const [],
    this.sessionHoles = const [],
    this.errorMessage,
    this.holesRevision = 0,
  });

  List<List<LatLng>> get allHoles => [...backendHoles, ...sessionHoles];

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    List<List<LatLng>>? backendHoles,
    List<List<LatLng>>? sessionHoles,
    String? errorMessage,
    int? holesRevision,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      backendHoles: backendHoles ?? this.backendHoles,
      sessionHoles: sessionHoles ?? this.sessionHoles,
      errorMessage: errorMessage ?? this.errorMessage,
      holesRevision: holesRevision ?? this.holesRevision,
    );
  }
}
