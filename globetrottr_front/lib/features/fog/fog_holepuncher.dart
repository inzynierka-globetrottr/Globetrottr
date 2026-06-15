import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class FogHolepuncher {
  static List<List<LatLng>> getHoleCoordinates({
    required LatLng? playerPosition,
    required double visionRadiusInMeters,
  }) {
    final List<List<LatLng>> holes = [];
    if (playerPosition != null) {
      holes.add(
        _calculateHoleCoordinates(
          center: playerPosition,
          radiusInMeters: visionRadiusInMeters,
        ),
      );
    }
    return holes;
  }

  static List<LatLng> _calculateHoleCoordinates({
    required LatLng center,
    required double radiusInMeters,
    //Number of edges to a holepunched "circle"
    int pointsCount = 36,
  }) {
    final List<LatLng> points = [];
    const double metersPerDegree = 111320.0;

    for (int i = 0; i < pointsCount; i++) {
      final double angle = (i * 2 * math.pi) / pointsCount;

      final double latOffset =
          (radiusInMeters * math.cos(angle)) / metersPerDegree;
      final double lngOffset =
          (radiusInMeters * math.sin(angle)) /
          (metersPerDegree * math.cos(center.latitude * math.pi / 180.0));

      points.add(
        LatLng(center.latitude + latOffset, center.longitude + lngOffset),
      );
    }
    return points;
  }
}
