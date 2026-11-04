import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Frames a friend's discovered area; null while there is too little of it
/// to frame.
CameraFit? fogCameraFit(
  List<List<LatLng>> holes, {
  EdgeInsets padding = const EdgeInsets.all(24),
}) {
  final points = [for (final hole in holes) ...hole];
  if (points.length < 2) return null;
  return CameraFit.coordinates(
    coordinates: points,
    padding: padding,
    maxZoom: 15,
  );
}
