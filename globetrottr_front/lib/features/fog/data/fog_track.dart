import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:latlong2/latlong.dart';

/// Points of a single recording session in chronological order.
///
/// Consecutive points are connected into stadiums when rendered;
/// points from different sessions are never connected.
class FogTrack {
  FogTrack({required this.sessionId, required List<LatLng> points})
    : assert(points.isNotEmpty, 'A track needs at least one point'),
      points = List.unmodifiable(points);

  final String sessionId;
  final List<LatLng> points;

  late final LatLngBounds bounds = LatLngBounds.fromPoints(points);

  /// Bounds extended on every side by [meters], so that a stroke drawn along
  /// the track with that radius is fully contained.
  LatLngBounds boundsWithMargin(double meters) {
    const metersPerDegree = 111320.0;
    final latitudeMargin = meters / metersPerDegree;
    final widestLatitude = math.min(
      math.max(bounds.south.abs(), bounds.north.abs()),
      85.0,
    );
    final longitudeMargin =
        meters / (metersPerDegree * math.cos(widestLatitude * math.pi / 180.0));

    return LatLngBounds(
      LatLng(
        math.max(bounds.south - latitudeMargin, -90.0),
        math.max(bounds.west - longitudeMargin, -180.0),
      ),
      LatLng(
        math.min(bounds.north + latitudeMargin, 90.0),
        math.min(bounds.east + longitudeMargin, 180.0),
      ),
    );
  }

  FogTrack append(LatLng point) =>
      FogTrack(sessionId: sessionId, points: [...points, point]);

  static List<FogTrack> fromPendingPoints(List<PendingPoint> pending) {
    final sorted = [...pending]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final bySession = <String, List<LatLng>>{};
    for (final point in sorted) {
      bySession
          .putIfAbsent(point.sessionId, () => [])
          .add(LatLng(point.latitude, point.longitude));
    }

    return [
      for (final entry in bySession.entries)
        FogTrack(sessionId: entry.key, points: entry.value),
    ];
  }
}
