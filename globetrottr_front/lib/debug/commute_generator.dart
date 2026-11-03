import 'dart:math' as math;

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

/// Trips that keep coming back to the same places, for looking at the
/// heatmap: a few routes around [home], some taken almost every time and
/// some once in a while, so places get very different session counts. Every
/// trip is its own session, out along one route and back; [wanderShare] of
/// the trips are free walks taken once.
///
/// Movement is organic: the heading of a route drifts a little at every step
/// (a correlated random walk), and every trip strays a few meters from the
/// route and back (an Ornstein-Uhlenbeck drift), like a real track that
/// follows a street but never exactly the same line.
List<TrackLogEntry> generateCommutes({
  required LatLng home,
  int trips = 60,
  int routes = 7,
  int seed = 7,
  double spacingMeters = 10,
  double wanderShare = 0.2,
}) {
  final random = math.Random(seed);
  const distance = Distance();

  double gaussian() {
    final u = 1 - random.nextDouble();
    return math.sqrt(-2 * math.log(u)) *
        math.cos(2 * math.pi * random.nextDouble());
  }

  /// A walk of [length] meters from [from] whose heading drifts by about
  /// [turnDegrees] per step, with a rare sharper turn at a junction.
  List<LatLng> walk(LatLng from, double length, double turnDegrees) {
    final points = [from];
    var heading = random.nextDouble() * 360;
    var bend = 0.0;
    for (var walked = 0.0; walked < length; walked += spacingMeters) {
      // The bend itself drifts, so curves last a while before they fade.
      bend = bend * 0.9 + gaussian() * turnDegrees;
      heading += bend;
      if (random.nextDouble() < 0.004) heading += gaussian() * 60;
      points.add(distance.offset(points.last, spacingMeters, heading));
    }
    return points;
  }

  final all = <List<LatLng>>[];
  for (var i = 0; i < routes; i++) {
    // Later routes branch off a point of an earlier one, so together they
    // make a network instead of a star around home.
    final branch = all.isEmpty ? null : all[random.nextInt(all.length)];
    final from = branch == null ? home : branch[random.nextInt(branch.length)];
    all.add(walk(from, 800 + random.nextDouble() * 2200, 1.2));
  }
  // The first routes are the daily ones, the last ones rare.
  final weights = [for (var i = 0; i < routes; i++) 1 / math.pow(i + 1, 1.4)];
  final total = weights.reduce((a, b) => a + b);

  List<LatLng> pick() {
    var roll = random.nextDouble() * total;
    for (var i = 0; i < routes; i++) {
      roll -= weights[i];
      if (roll <= 0) return all[i];
    }
    return all.last;
  }

  final entries = <TrackLogEntry>[];
  var timestamp = DateTime.utc(2026, 1, 5, 8).millisecondsSinceEpoch;
  for (var trip = 0; trip < trips; trip++) {
    final session = 'commute_${seed}_$trip';
    final paths = random.nextDouble() < wanderShare
        ? [walk(home, 1000 + random.nextDouble() * 3000, 3)]
        : [pick()];
    var north = 0.0;
    var east = 0.0;
    for (final path in paths) {
      for (final point in [...path, ...path.reversed]) {
        north = north * 0.92 + gaussian() * 0.9;
        east = east * 0.92 + gaussian() * 0.9;
        final at = distance.offset(
          distance.offset(point, north, 0),
          east,
          90,
        );
        entries.add(
          TrackLogEntry(
            sessionId: session,
            timestampMs: timestamp,
            latitude: at.latitude,
            longitude: at.longitude,
          ),
        );
        timestamp += 7000;
      }
    }
    timestamp += Duration.millisecondsPerDay;
  }
  return entries;
}
