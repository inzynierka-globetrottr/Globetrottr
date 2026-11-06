import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:latlong2/latlong.dart';

import 'fog_test_helpers.dart';

/// A flutter_map camera over Krakow on a 400x800 screen, for map layers that
/// still take the camera of the map package.
MapCamera mapCameraAt({
  double? zoom,
  double rotation = 0,
  double lat = krakowLat,
  double lng = krakowLng,
}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: LatLng(lat, lng),
    zoom: zoom ?? FogConfig.baseZoom.toDouble(),
    rotation: rotation,
    nonRotatedSize: const math.Point<double>(400, 800),
  );
}

Offset mapScreenOf(MapCamera camera, double lat, double lng) {
  final p = camera.latLngToScreenPoint(LatLng(lat, lng));
  return Offset(p.x, p.y);
}
