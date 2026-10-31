import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

typedef JourneyImportResult = ({int points, double km, bool cancelled});

/// Feeds [journey] to [importChunk] chunk by chunk, so only one chunk of
/// fixes is ever in memory. [isCancelled] is checked between chunks.
Future<JourneyImportResult> importJourney(
  ExplorerJourney journey, {
  required Future<void> Function(List<TrackLogEntry> chunk) importChunk,
  int chunkPoints = 50000,
  bool Function()? isCancelled,
  void Function(double progress)? onProgress,
}) async {
  var points = 0;
  while (!journey.isDone) {
    if (isCancelled?.call() ?? false) {
      return (points: points, km: journey.travelledKm, cancelled: true);
    }
    final chunk = journey.next(maxPoints: chunkPoints);
    await importChunk(chunk);
    points += chunk.length;
    if (journey.totalKm > 0) {
      onProgress?.call((journey.travelledKm / journey.totalKm).clamp(0, 1));
    }
  }
  onProgress?.call(1);
  return (points: points, km: journey.travelledKm, cancelled: false);
}
