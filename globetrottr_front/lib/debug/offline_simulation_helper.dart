import 'dart:math' as math;
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:latlong2/latlong.dart';

class OfflineSimulationHelper {
  static List<PendingPoint> generatePoints({
    required LatLng startCenter,
    int count = 50000,
    int totalDays = 21,
  }) {
    if (count <= 0) return [];

    final random = math.Random(42);
    final List<PendingPoint> points = [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final totalDurationMs = Duration(days: totalDays).inMilliseconds;
    final intervalMs = math.max(1000, totalDurationMs ~/ count);
    int currentTimestamp = now - totalDurationMs;

    double currentLat = startCenter.latitude;
    double currentLng = startCenter.longitude;
    double heading = random.nextDouble() * 2 * math.pi;

    final pointsPerSession = math.max(200, count ~/ (totalDays * 2));
    int sessionIndex = 1;
    String currentSessionId = 'sim_session_$sessionIndex';

    for (int i = 0; i < count; i++) {
      if (i > 0 && i % pointsPerSession == 0) {
        sessionIndex++;
        currentSessionId = 'sim_session_$sessionIndex';
        currentTimestamp += const Duration(hours: 8).inMilliseconds;
      }

      points.add(
        PendingPoint(
          sessionId: currentSessionId,
          latitude: currentLat,
          longitude: currentLng,
          timestamp: currentTimestamp,
        ),
      );

      heading += (random.nextDouble() - 0.5) * 0.4;
      const stepDistanceDegrees = 0.00003;

      currentLat += math.cos(heading) * stepDistanceDegrees;
      currentLng += math.sin(heading) * stepDistanceDegrees;
      currentTimestamp += intervalMs;
    }

    return points;
  }
}
