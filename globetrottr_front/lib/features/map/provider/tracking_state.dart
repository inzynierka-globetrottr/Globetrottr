import 'package:globetrottr_front/features/fog/data/fog_track.dart';
import 'package:latlong2/latlong.dart';

class TrackingState {
  final bool isTracking;
  final bool isRecording;
  final LatLng? currentPosition;
  final List<List<LatLng>> backendHoles;
  final List<FogTrack> sessionTracks;
  final String? errorMessage;
  final int holesRevision;

  const TrackingState({
    this.isTracking = false,
    this.isRecording = false,
    this.currentPosition,
    this.backendHoles = const [],
    this.sessionTracks = const [],
    this.errorMessage,
    this.holesRevision = 0,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isRecording,
    LatLng? currentPosition,
    List<List<LatLng>>? backendHoles,
    List<FogTrack>? sessionTracks,
    String? errorMessage,
    int? holesRevision,
    bool clearError = false,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      backendHoles: backendHoles ?? this.backendHoles,
      sessionTracks: sessionTracks ?? this.sessionTracks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      holesRevision: holesRevision ?? this.holesRevision,
    );
  }
}
