import 'dart:math' as math;

const double _earthRadiusMeters = 6378137.0;
const double _tileSizePixels = 256.0;

/// Ground resolution of the Web Mercator map at the given latitude and zoom.
double metersPerPixel({required double latitude, required double zoom}) {
  const metersPerPixelAtEquator =
      2 * math.pi * _earthRadiusMeters / _tileSizePixels;
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
