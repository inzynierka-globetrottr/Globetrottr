import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/recorded_points_source.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

import '../support/fog_render_helpers.dart';
import '../support/fog_test_helpers.dart';
import '../support/in_memory_track_log_storage.dart';

class _GatedStorage extends InMemoryTrackLogStorage {
  final List<Completer<void>> gates = [];
  int queries = 0;

  @override
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  }) async {
    queries++;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return super.entriesInBounds(
      south: south,
      west: west,
      north: north,
      east: east,
      limit: limit,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<InMemoryTrackLogStorage> filled() async {
    final log = InMemoryTrackLogStorage();
    await log.appendAll(walkEast('a', points: 30));
    await log.appendAll(
      walkEast('far', points: 5, startLat: krakowLat + 1),
    );
    return log;
  }

  group('RecordedPointsSource', () {
    test('loads the points around the camera', () async {
      final source = RecordedPointsSource(await filled());

      await source.ensure(cameraAt());

      expect(source.points.length, 30);
      expect(source.points.every((e) => e.sessionId == 'a'), isTrue);
      source.dispose();
    });

    test('loads nothing when the map is too far out', () async {
      final storage = _GatedStorage();
      await storage.appendAll(walkEast('a', points: 5));
      final source = RecordedPointsSource(storage);

      await source.ensure(cameraAt(zoom: 9));

      expect(source.points, isEmpty);
      expect(storage.queries, 0);
      source.dispose();
    });

    test('clears the points when the map is zoomed out', () async {
      final source = RecordedPointsSource(await filled());
      await source.ensure(cameraAt());

      await source.ensure(cameraAt(zoom: 9));

      expect(source.points, isEmpty);
      source.dispose();
    });

    test(
      'does not query again while the view stays inside the loaded area',
      () async {
        final storage = _GatedStorage();
        await storage.appendAll(walkEast('a', points: 30));
        final source = RecordedPointsSource(storage);
        final first = source.ensure(cameraAt());
        storage.gates.last.complete();
        await first;

        final nearby = cameraAt(
          lng: offsetMeters(krakowLat, krakowLng, east: 40).lng,
        );
        await source.ensure(nearby);
        await source.ensure(cameraAt());

        expect(storage.queries, 1);
        source.dispose();
      },
    );

    test('loads again after the view leaves the loaded area', () async {
      final storage = _GatedStorage();
      await storage.appendAll(walkEast('a', points: 30));
      final source = RecordedPointsSource(storage);
      final first = source.ensure(cameraAt());
      storage.gates.last.complete();
      await first;

      final away = cameraAt(
        lat: offsetMeters(krakowLat, krakowLng, north: 5000).lat,
      );
      final second = source.ensure(away);
      storage.gates.last.complete();
      await second;

      expect(storage.queries, 2);
      expect(source.points, isEmpty);
      source.dispose();
    });

    test('drops an answer that arrives after a newer request', () async {
      final storage = _GatedStorage();
      await storage.appendAll(walkEast('a', points: 30));
      final source = RecordedPointsSource(storage);
      final stale = source.ensure(cameraAt());
      final away = cameraAt(
        lat: offsetMeters(krakowLat, krakowLng, north: 5000).lat,
      );
      final fresh = source.ensure(away);

      storage.gates[1].complete();
      await fresh;
      storage.gates[0].complete();
      await stale;

      expect(source.points, isEmpty);
      source.dispose();
    });

    test('adds a new point that is inside the loaded area', () async {
      final source = RecordedPointsSource(await filled());
      await source.ensure(cameraAt());
      var notified = 0;
      source.addListener(() => notified++);
      final at = offsetMeters(krakowLat, krakowLng, north: 20);

      source.add(logEntry('a', 99, at, id: 500));

      expect(source.points.length, 31);
      expect(source.points.last.id, 500);
      expect(notified, 1);
      source.dispose();
    });

    test('ignores a new point outside the loaded area', () async {
      final source = RecordedPointsSource(await filled());
      await source.ensure(cameraAt());

      source.add(
        logEntry('a', 99, (lat: krakowLat + 2, lng: krakowLng), id: 500),
      );

      expect(source.points.length, 30);
      source.dispose();
    });

    test('ignores a broken camera', () async {
      final storage = _GatedStorage();
      final source = RecordedPointsSource(storage);

      await source.ensure(cameraAt(zoom: double.nan));

      expect(storage.queries, 0);
      source.dispose();
    });

    test('says when there are more points than it shows', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a', points: 50));
      final source = RecordedPointsSource(log, maxPoints: 20);

      await source.ensure(cameraAt());

      expect(source.points.length, 20);
      source.dispose();
    });

    test('clear forgets the points and the loaded area', () async {
      final storage = _GatedStorage();
      await storage.appendAll(walkEast('a', points: 30));
      final source = RecordedPointsSource(storage);
      final first = source.ensure(cameraAt());
      storage.gates.last.complete();
      await first;

      source.clear();
      final second = source.ensure(cameraAt());
      storage.gates.last.complete();
      await second;

      expect(storage.queries, 2);
      expect(source.points.length, 30);
      source.dispose();
    });

    test('a query that finishes after dispose is ignored', () async {
      final storage = _GatedStorage();
      await storage.appendAll(walkEast('a', points: 30));
      final source = RecordedPointsSource(storage);
      final pending = source.ensure(cameraAt());

      source.dispose();
      storage.gates.last.complete();
      await pending;

      expect(source.points, isEmpty);
    });
  });
}
