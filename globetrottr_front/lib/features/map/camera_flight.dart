import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

typedef CameraView = ({LatLng center, double zoom});

/// A straight move of the camera from one view to another; [at] takes the
/// progress from 0 to 1. The antimeridian is ignored.
class CameraFlight {
  const CameraFlight({required this.from, required this.to});

  final CameraView from;
  final CameraView to;

  bool get isStill => from == to;

  CameraView at(double t) {
    if (t <= 0) return from;
    if (t >= 1) return to;
    double lerp(double a, double b) => a + (b - a) * t;
    return (
      center: LatLng(
        lerp(from.center.latitude, to.center.latitude),
        lerp(from.center.longitude, to.center.longitude),
      ),
      zoom: lerp(from.zoom, to.zoom),
    );
  }
}

const _userGestures = {
  MapEventSource.dragStart,
  MapEventSource.multiFingerGestureStart,
  MapEventSource.doubleTap,
  MapEventSource.doubleTapHold,
  MapEventSource.scrollWheel,
};

/// Whether an event from [source] means the user took over the camera, so a
/// flight in progress has to stop.
bool interruptsCameraFlight(MapEventSource source) =>
    _userGestures.contains(source);
