import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

/// Decides whether two consecutive points of a session are joined by a
/// stadium or the later one starts a new path (a lone disc).
///
/// A longer gap means the device saw nothing in between (a tunnel, a flight,
/// a phone switched off), so drawing the straight line would invent
/// discoveries and, for a jump of hundreds of kilometres, touch thousands of
/// tiles. The test works on base level pixels: the radius of the later point
/// is the pixel length of [radiusMeters] at its latitude, so the limit is in
/// real meters at any latitude.
///
/// [maxTiles] is a safety net independent of the meter limit: a path whose
/// bounding box covers more tiles is cut too, so one point can never need
/// more memory than that, whatever the constants or the latitude.
class FogSegmentRule {
  const FogSegmentRule({
    required this.radiusMeters,
    required this.maxSegmentMeters,
    this.maxTiles = FogConfig.maxTilesPerSegment,
  });

  final double radiusMeters;
  final double maxSegmentMeters;
  final int maxTiles;

  bool connects(FogPathPoint a, FogPathPoint b) {
    final radius = b.radius;
    final limit = maxSegmentMeters / radiusMeters * radius;
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    if (dx * dx + dy * dy > limit * limit) return false;
    return _tileSpan(a.x, b.x, radius) * _tileSpan(a.y, b.y, radius) <=
        maxTiles;
  }

  static int _tileSpan(double a, double b, double radius) {
    const size = FogTileId.size;
    final low = a < b ? a : b;
    final high = a < b ? b : a;
    return ((high + radius) / size).floor() -
        ((low - radius) / size).floor() +
        1;
  }
}
