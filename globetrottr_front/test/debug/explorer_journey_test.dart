import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

import '../support/fog_test_helpers.dart';
import '../support/explorer_route_generator.dart';

const _krakow = LatLng(50.0614, 19.9383);

List<TrackLogEntry> _drain(ExplorerJourney journey, {int maxPoints = 5000}) {
  final all = <TrackLogEntry>[];
  while (!journey.isDone) {
    all.addAll(journey.next(maxPoints: maxPoints));
  }
  return all;
}

Map<String, List<TrackLogEntry>> _bySession(List<TrackLogEntry> entries) {
  final map = <String, List<TrackLogEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.sessionId, () => []).add(e);
  }
  return map;
}

void main() {
  group('ExplorerJourney', () {
    test('gives the same points in chunks as generate() at once', () {
      final whole = ExplorerRouteGenerator.generate(
        start: _krakow,
        totalKm: 80,
      );
      final chunked = _drain(
        ExplorerJourney(start: _krakow, totalKm: 80),
        maxPoints: 777,
      );

      expect(chunked.length, whole.length);
      for (var i = 0; i < whole.length; i += 97) {
        expect(chunked[i].latitude, whole[i].latitude);
        expect(chunked[i].longitude, whole[i].longitude);
        expect(chunked[i].sessionId, whole[i].sessionId);
        expect(chunked[i].timestampMs, whole[i].timestampMs);
      }
    });

    test('a chunk never holds more than the requested points', () {
      final journey = ExplorerJourney(start: _krakow, totalKm: 50);

      while (!journey.isDone) {
        expect(journey.next(maxPoints: 1000).length, lessThanOrEqualTo(1000));
      }
    });

    test('a huge journey is produced lazily, chunk by chunk', () {
      final journey = ExplorerJourney(
        start: _krakow,
        totalKm: 100000,
        region: ExplorerRegion.europe,
      );

      final chunk = journey.next(maxPoints: 2000);

      expect(chunk, hasLength(2000));
      expect(journey.isDone, isFalse);
      expect(journey.travelledKm, lessThan(100));
    });

    test('reports the travelled distance and finishes at the total', () {
      final journey = ExplorerJourney(start: _krakow, totalKm: 40);

      final entries = _drain(journey);

      expect(journey.isDone, isTrue);
      expect(journey.travelledKm, closeTo(40, 0.1));
      var total = 0.0;
      for (final session in _bySession(entries).values) {
        total += pathMeters(session);
      }
      expect(total / 1000, closeTo(40, 2));
      expect(journey.next(), isEmpty);
    });
  });

  group('a continent journey', () {
    late List<TrackLogEntry> europe;
    setUpAll(() {
      europe = _drain(
        ExplorerJourney(
          start: _krakow,
          totalKm: 6000,
          region: ExplorerRegion.europe,
          spacingFollowsSpeed: true,
        ),
        maxPoints: 20000,
      );
    });

    test('stays within the continent', () {
      const region = ExplorerRegion.europe;
      for (final e in europe) {
        expect(
          e.latitude,
          inInclusiveRange(region.south - 0.5, region.north + 0.5),
        );
        expect(e.longitude, inInclusiveRange(region.west - 1, region.east + 1));
      }
    });

    test('crosses the continent instead of circling the start', () {
      const distance = Distance();
      var farthest = 0.0;
      for (final e in europe) {
        final d = distance.as(
          LengthUnit.Kilometer,
          _krakow,
          LatLng(e.latitude, e.longitude),
        );
        if (d > farthest) farthest = d;
      }

      expect(farthest, greaterThan(1000));
    });

    test('is one connected journey: each trip starts near the last end', () {
      final sessions = _bySession(europe).values.toList();
      expect(sessions.length, greaterThan(20));
      const distance = Distance();
      for (var i = 1; i < sessions.length; i++) {
        final end = sessions[i - 1].last;
        final start = sessions[i].first;
        expect(
          distance.as(
            LengthUnit.Kilometer,
            LatLng(end.latitude, end.longitude),
            LatLng(start.latitude, start.longitude),
          ),
          lessThan(10),
        );
      }
    });

    test('spaces the fixes by speed, like a GPS logging once a second', () {
      var fast = 0;
      for (final session in _bySession(europe).values) {
        for (var i = 1; i < session.length; i++) {
          final gap = pathMeters([
            session[i - 1],
            session[i],
          ]);
          expect(gap, greaterThan(9.5));
          if (gap > 18) fast++;
        }
      }

      expect(fast, greaterThan(europe.length ~/ 4));
    });

    test('separate runs never share a session id', () {
      Set<String> sessions(int seed) => {
        for (final e in ExplorerRouteGenerator.generate(
          start: _krakow,
          totalKm: 200,
          seed: seed,
        ))
          e.sessionId,
      };

      final first = sessions(1);
      final second = sessions(2);

      expect(first, isNotEmpty);
      expect(first.intersection(second), isEmpty);
      expect(sessions(1), first);
    });

    test('starts in the middle of the continent when the start is outside', () {
      const region = ExplorerRegion.southAmerica;
      final first = ExplorerJourney(
        start: _krakow,
        totalKm: 10,
        region: region,
      ).next(maxPoints: 1).single;

      expect(first.latitude, inInclusiveRange(region.south, region.north));
      expect(first.longitude, inInclusiveRange(region.west, region.east));
    });
  });
}
