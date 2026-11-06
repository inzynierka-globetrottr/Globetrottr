import 'package:flutter_map/flutter_map.dart';

/// Rejects every move that would leave the camera with a NaN or infinite
/// center or zoom, so the map stays where it was.
///
/// The pinch zoom of flutter_map 6 adds a correction to the gesture scale
/// that can bring it to zero or below when the fingers first spread and then
/// close; the logarithm of it is then infinite or NaN and the tile layer
/// crashes with "Infinity or NaN toInt". Zoom limits alone do not help,
/// because a NaN zoom passes any clamp.
class FiniteCameraConstraint extends CameraConstraint {
  const FiniteCameraConstraint();

  @override
  MapCamera? constrain(MapCamera camera) {
    final finite =
        camera.zoom.isFinite &&
        camera.center.latitude.isFinite &&
        camera.center.longitude.isFinite;
    return finite ? camera : null;
  }
}
