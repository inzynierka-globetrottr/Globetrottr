import 'package:flutter_map/flutter_map.dart';

/// Explains why [camera] is unusable, or returns null when it is fine.
///
/// Used in dev mode to find out which map event first leaves the camera with
/// a NaN or infinite value, which later crashes the tile layer.
String? describeCameraProblem(MapCamera camera) {
  final problems = <String>[];
  final center = camera.center;
  if (!center.latitude.isFinite || !center.longitude.isFinite) {
    problems.add('center=$center');
  }
  if (!camera.zoom.isFinite) problems.add('zoom=${camera.zoom}');
  if (!camera.rotation.isFinite) problems.add('rotation=${camera.rotation}');
  final size = camera.nonRotatedSize;
  if (!size.x.isFinite || !size.y.isFinite || size.x <= 0 || size.y <= 0) {
    problems.add('size=$size');
  }
  return problems.isEmpty ? null : problems.join(', ');
}
