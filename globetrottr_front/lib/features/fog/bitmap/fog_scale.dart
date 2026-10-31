import 'dart:math' as math;

import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

const double _earthRadiusMeters = 6378137.0;

/// Ground resolution of the Web Mercator map at the given latitude and zoom.
double metersPerPixel({required double latitude, required double zoom}) {
  const metersPerPixelAtEquator =
      2 * math.pi * _earthRadiusMeters / FogTileId.size;
  return metersPerPixelAtEquator *
      math.cos(latitude * math.pi / 180.0) /
      math.pow(2, zoom);
}

double metersToPixels({
  required double meters,
  required double latitude,
  required double zoom,
}) {
  return meters / metersPerPixel(latitude: latitude, zoom: zoom);
}
