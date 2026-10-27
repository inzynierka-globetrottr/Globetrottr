import 'dart:math' as math;

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

/// Synthetic journeys of a keen explorer: long motorway stretches, winding
/// roads and city street grids, one session per trip, one trip per day.
/// Used to stress the fog with realistic, connected, large amounts of data.
abstract final class ExplorerRouteGenerator {
  static const double _metersPerDegree = 111319.49;

  static List<TrackLogEntry> generate({
    required LatLng start,
    required double totalKm,
    double spacingMeters = 10,
    int seed = 7,
  }) {
    if (totalKm <= 0) return const [];
    final random = math.Random(seed);
    final entries = <TrackLogEntry>[];

    var remainingMeters = totalKm * 1000;
    var lat = start.latitude;
    var lng = start.longitude;
    var day = 0;
    final firstDay = DateTime.utc(2026, 1, 1, 8).millisecondsSinceEpoch;

    while (remainingMeters > 0) {
      final tripMeters = math.min(
        remainingMeters,
        (20 + random.nextDouble() * 130) * 1000,
      );
      remainingMeters -= tripMeters;

      lat += (random.nextDouble() - 0.5) * 0.04;
      lng += (random.nextDouble() - 0.5) * 0.06;
      var heading = random.nextDouble() * 2 * math.pi;
      var timestamp = firstDay + day * Duration.millisecondsPerDay;
      day++;
      final session = 'trip_$day';

      var travelled = 0.0;
      var segmentLeft = 0.0;
      var segment = _Segment.highway;
      while (travelled < tripMeters) {
        if (segmentLeft <= 0) {
          segment = _Segment.values[random.nextInt(_Segment.values.length)];
          segmentLeft =
              segment.minMeters +
              random.nextDouble() * (segment.maxMeters - segment.minMeters);
          if (segment == _Segment.city) {
            heading = (heading / (math.pi / 2)).round() * (math.pi / 2);
          }
        }

        final speed = segment.speed * (0.85 + random.nextDouble() * 0.3);
        entries.add(
          TrackLogEntry(
            sessionId: session,
            timestampMs: timestamp,
            latitude: lat,
            longitude: lng,
            accuracy: 4 + random.nextDouble() * 6,
            speed: speed,
          ),
        );

        if (segment == _Segment.city) {
          if (random.nextDouble() < spacingMeters / 180) {
            heading += (random.nextBool() ? 1 : -1) * math.pi / 2;
          }
        } else {
          heading += (random.nextDouble() - 0.5) * segment.wobble;
        }

        lat += math.cos(heading) * spacingMeters / _metersPerDegree;
        lng +=
            math.sin(heading) *
            spacingMeters /
            (_metersPerDegree * math.cos(lat * math.pi / 180));
        lat = lat.clamp(-80.0, 80.0);
        lng = ((lng + 180) % 360) - 180;

        timestamp += (spacingMeters / speed * 1000).round();
        travelled += spacingMeters;
        segmentLeft -= spacingMeters;
      }
    }
    return entries;
  }
}

enum _Segment {
  highway(25, 0.01, 20000, 80000),
  winding(14, 0.25, 3000, 15000),
  city(5, 0, 2000, 10000);

  const _Segment(this.speed, this.wobble, this.minMeters, this.maxMeters);

  final double speed;
  final double wobble;
  final double minMeters;
  final double maxMeters;
}
