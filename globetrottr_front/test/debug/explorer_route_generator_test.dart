import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

import '../support/fog_test_helpers.dart';

Map<String, List<TrackLogEntry>> _bySession(List<TrackLogEntry> entries) {
  final map = <String, List<TrackLogEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.sessionId, () => []).add(e);
  }
  return map;
}

void main() {
  const start = LatLng(50.0614, 19.9383);

  group('ExplorerRouteGenerator', () {
    test('covers roughly the requested distance', () {
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 120,
      );

      var total = 0.0;
      for (final session in _bySession(entries).values) {
        total += pathMeters(session);
      }
      expect(total / 1000, closeTo(120, 6));
    });

    test('keeps the requested spacing between consecutive fixes', () {
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 30,
      );

      for (final session in _bySession(entries).values) {
        for (var i = 1; i < session.length; i++) {
          final gap = pathMeters([
            session[i - 1],
            session[i],
          ]);
          expect(gap, closeTo(10, 0.5));
        }
      }
    });

    test('splits the journey into several sessions on different days', () {
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 400,
      );

      final sessions = _bySession(entries);
      final days = {
        for (final e in entries)
          DateTime.fromMillisecondsSinceEpoch(
            e.timestampMs,
            isUtc: true,
          ).day,
      };
      expect(sessions.length, greaterThan(2));
      expect(days.length, greaterThanOrEqualTo(sessions.length ~/ 2));
    });

    test('timestamps increase and speeds are plausible', () {
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 60,
      );

      for (final session in _bySession(entries).values) {
        for (var i = 1; i < session.length; i++) {
          expect(
            session[i].timestampMs,
            greaterThan(session[i - 1].timestampMs),
          );
        }
        final seconds =
            (session.last.timestampMs - session.first.timestampMs) / 1000;
        expect(pathMeters(session) / seconds, inInclusiveRange(1.0, 40.0));
      }
    });

    test('is deterministic for a seed and differs between seeds', () {
      final a = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 20,
        seed: 3,
      );
      final b = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 20,
        seed: 3,
      );
      final c = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 20,
        seed: 4,
      );

      expect(a.length, b.length);
      expect(a.last.latitude, b.last.latitude);
      expect(a.last.longitude, isNot(c.last.longitude));
    });

    test('starts near the given position and stays on Earth', () {
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 500,
      );

      final first = entries.first;
      expect((first.latitude - start.latitude).abs(), lessThan(0.1));
      for (final e in entries) {
        expect(e.latitude, inInclusiveRange(-85, 85));
        expect(e.longitude, inInclusiveRange(-180, 180));
      }
    });

    test('records accuracy and speed like a real fix', () {
      final entries = ExplorerRouteGenerator.generate(start: start, totalKm: 5);

      expect(
        entries.every((e) => e.accuracy != null && e.speed != null),
        isTrue,
      );
    });

    test('nothing is generated for zero kilometers', () {
      expect(
        ExplorerRouteGenerator.generate(start: start, totalKm: 0),
        isEmpty,
      );
    });
  });
}
