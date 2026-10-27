import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/offline_simulation_helper.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('OfflineSimulationHelper', () {
    test('generatePoints returns requested count with valid properties', () {
      const count = 1000;
      const center = LatLng(50.0614, 19.9383);

      final points = OfflineSimulationHelper.generatePoints(
        startCenter: center,
        count: count,
        totalDays: 7,
      );

      expect(points.length, equals(count));

      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        expect(point.sessionId, isNotEmpty);
        expect(point.latitude, inInclusiveRange(-90.0, 90.0));
        expect(point.longitude, inInclusiveRange(-180.0, 180.0));

        if (i > 0) {
          expect(
            point.timestamp,
            greaterThanOrEqualTo(points[i - 1].timestamp),
          );
        }
      }
    });

    test('generatePoints groups points into multiple session IDs', () {
      final points = OfflineSimulationHelper.generatePoints(
        startCenter: const LatLng(50.0614, 19.9383),
        count: 5000,
        totalDays: 14,
      );

      final uniqueSessions = points.map((p) => p.sessionId).toSet();
      expect(uniqueSessions.length, greaterThan(1));
    });

    test('toTrackLog keeps sessions, times and positions', () {
      final points = OfflineSimulationHelper.generatePoints(
        startCenter: const LatLng(50.0614, 19.9383),
        count: 300,
        totalDays: 2,
      );

      final log = OfflineSimulationHelper.toTrackLog(points);

      expect(log.length, points.length);
      expect(log.first.sessionId, points.first.sessionId);
      expect(log.last.timestampMs, points.last.timestamp);
      expect(log.last.latitude, points.last.latitude);
      expect(log.last.longitude, points.last.longitude);
    });
  });
}
