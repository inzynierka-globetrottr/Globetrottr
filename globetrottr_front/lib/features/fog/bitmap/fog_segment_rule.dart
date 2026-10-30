/// Decides whether two consecutive points of a session are joined by a
/// stadium or the later one starts a new path (a lone disc).
///
/// A longer gap means the device saw nothing in between (a tunnel, a flight,
/// a phone switched off), so drawing the straight line would invent
/// discoveries and, for a jump of hundreds of kilometres, touch thousands of
/// tiles. The test works on base level pixels: `radius` is the pixel length
/// of [radiusMeters] at the point's latitude, so the limit is in real meters
/// at any latitude.
class FogSegmentRule {
  const FogSegmentRule({
    required this.radiusMeters,
    required this.maxSegmentMeters,
  });

  final double radiusMeters;
  final double maxSegmentMeters;

  bool connects(double ax, double ay, double bx, double by, double radius) {
    final limit = maxSegmentMeters / radiusMeters * radius;
    final dx = bx - ax;
    final dy = by - ay;
    return dx * dx + dy * dy <= limit * limit;
  }
}
