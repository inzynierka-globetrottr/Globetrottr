import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

/// Synthetic journeys of a keen explorer: long motorway stretches, winding
/// roads and city street grids, one session per trip, one trip per day.
/// Used to stress the fog with realistic, connected, large amounts of data.
abstract final class ExplorerRouteGenerator {
  static List<TrackLogEntry> generate({
    required LatLng start,
    required double totalKm,
    double spacingMeters = 10,
    int seed = 7,
  }) {
    final journey = ExplorerJourney(
      start: start,
      totalKm: totalKm,
      spacingMeters: spacingMeters,
      seed: seed,
    );
    final entries = <TrackLogEntry>[];
    while (!journey.isDone) {
      entries.addAll(journey.next());
    }
    return entries;
  }
}
