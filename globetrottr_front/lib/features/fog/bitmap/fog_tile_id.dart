import 'dart:math' as math;

import 'package:meta/meta.dart';

@immutable
/// Address of a 256x256 px fog tile in the standard Web Mercator XYZ grid.
class FogTileId {
  const FogTileId(this.z, this.x, this.y);

  factory FogTileId.fromKey(int key) => FogTileId(
    key >> 52,
    (key >> 26) & _coordinateMask,
    key & _coordinateMask,
  );

  static const int size = 256;
  static const int _coordinateMask = (1 << 26) - 1;

  final int z;
  final int x;
  final int y;

  int get key => (z << 52) | (x << 26) | y;

  FogTileId ancestorAt(int zoom) {
    assert(zoom >= 0 && zoom <= z, 'zoom must not be deeper than the tile');
    final shift = z - zoom;
    return FogTileId(zoom, x >> shift, y >> shift);
  }

  @override
  bool operator ==(Object other) =>
      other is FogTileId && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => 'FogTileId($z/$x/$y)';
}

/// Conversions between WGS 84 and Web Mercator world pixels (256 px tiles).
abstract final class FogMercator {
  static const double maxLatitude = 85.0511287798;

  static double worldSize(num zoom) =>
      FogTileId.size * math.pow(2, zoom).toDouble();

  static double lngToX(double lng, int zoom) =>
      (lng + 180.0) / 360.0 * worldSize(zoom);

  static double latToY(double lat, int zoom) {
    final clamped = lat.clamp(-maxLatitude, maxLatitude);
    final sine = math.sin(clamped * math.pi / 180.0);
    final mercator = math.log((1 + sine) / (1 - sine)) / (4 * math.pi);
    return (0.5 - mercator) * worldSize(zoom);
  }

  static double xToLng(double x, int zoom) =>
      x / worldSize(zoom) * 360.0 - 180.0;

  static double yToLat(double y, int zoom) {
    final n = math.pi - 2 * math.pi * y / worldSize(zoom);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }
}
