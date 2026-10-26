import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_track.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:latlong2/latlong.dart';

PendingPoint _point(String sessionId, int timestamp, double lat, double lng) {
  return PendingPoint(
    sessionId: sessionId,
    latitude: lat,
    longitude: lng,
    timestamp: timestamp,
  );
}

void main() {
  group('FogTrack.fromPendingPoints', () {
    test('returns no tracks for no points', () {
      expect(FogTrack.fromPendingPoints([]), isEmpty);
    });

    test('creates one track per session without mixing points', () {
      final tracks = FogTrack.fromPendingPoints([
        _point('a', 1, 50.0, 19.0),
        _point('b', 2, 51.0, 20.0),
        _point('a', 3, 50.1, 19.1),
        _point('b', 4, 51.1, 20.1),
      ]);

      expect(tracks.map((t) => t.sessionId), ['a', 'b']);
      expect(tracks[0].points, [
        const LatLng(50.0, 19.0),
        const LatLng(50.1, 19.1),
      ]);
      expect(tracks[1].points, [
        const LatLng(51.0, 20.0),
        const LatLng(51.1, 20.1),
      ]);
    });

    test('orders points within a session by timestamp', () {
      final tracks = FogTrack.fromPendingPoints([
        _point('a', 30, 50.3, 19.3),
        _point('a', 10, 50.1, 19.1),
        _point('a', 20, 50.2, 19.2),
      ]);

      expect(tracks.single.points, [
        const LatLng(50.1, 19.1),
        const LatLng(50.2, 19.2),
        const LatLng(50.3, 19.3),
      ]);
    });

    test('orders tracks by their first timestamp', () {
      final tracks = FogTrack.fromPendingPoints([
        _point('late', 100, 50.0, 19.0),
        _point('early', 5, 51.0, 20.0),
        _point('late', 200, 50.1, 19.1),
      ]);

      expect(tracks.map((t) => t.sessionId), ['early', 'late']);
    });

    test('keeps a single-point session as a one-point track', () {
      final tracks = FogTrack.fromPendingPoints([_point('a', 1, 50.0, 19.0)]);

      expect(tracks.single.points, [const LatLng(50.0, 19.0)]);
    });
  });

  group('FogTrack', () {
    test('append returns a new track and leaves the original unchanged', () {
      final original = FogTrack(
        sessionId: 'a',
        points: const [LatLng(50.0, 19.0)],
      );

      final extended = original.append(const LatLng(50.1, 19.1));

      expect(original.points, [const LatLng(50.0, 19.0)]);
      expect(extended.sessionId, 'a');
      expect(extended.points, [
        const LatLng(50.0, 19.0),
        const LatLng(50.1, 19.1),
      ]);
    });

    test('points cannot be modified from outside', () {
      final source = [const LatLng(50.0, 19.0)];
      final track = FogTrack(sessionId: 'a', points: source);

      source.add(const LatLng(60.0, 20.0));

      expect(track.points, [const LatLng(50.0, 19.0)]);
      expect(
        () => track.points.add(const LatLng(1.0, 1.0)),
        throwsUnsupportedError,
      );
    });

    test('bounds cover all points', () {
      final track = FogTrack(
        sessionId: 'a',
        points: const [
          LatLng(50.0, 19.5),
          LatLng(50.2, 19.0),
          LatLng(49.9, 19.8),
        ],
      );

      expect(track.bounds.south, 49.9);
      expect(track.bounds.north, 50.2);
      expect(track.bounds.west, 19.0);
      expect(track.bounds.east, 19.8);
    });

    test('boundsWithMargin extends bounds by the given distance', () {
      final track = FogTrack(
        sessionId: 'a',
        points: const [LatLng(50.0, 19.0), LatLng(50.1, 19.1)],
      );

      final padded = track.boundsWithMargin(1113.2);

      expect(padded.south, closeTo(50.0 - 0.01, 1e-6));
      expect(padded.north, closeTo(50.1 + 0.01, 1e-6));
      expect(padded.west, lessThan(19.0 - 0.01));
      expect(padded.east, greaterThan(19.1 + 0.01));
    });

    test('boundsWithMargin stays within valid coordinates', () {
      final track = FogTrack(
        sessionId: 'a',
        points: const [LatLng(89.9999, 179.9999)],
      );

      final padded = track.boundsWithMargin(100000);

      expect(padded.north, lessThanOrEqualTo(90));
      expect(padded.east, lessThanOrEqualTo(180));
    });
  });
}
