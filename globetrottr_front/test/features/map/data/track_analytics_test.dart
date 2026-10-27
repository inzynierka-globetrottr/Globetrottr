import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/track_analytics.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

TrackLogEntry _entry(
  String session,
  DateTime utc,
  double lat,
  double lng, {
  double? speed,
}) {
  return TrackLogEntry(
    sessionId: session,
    timestampMs: utc.millisecondsSinceEpoch,
    latitude: lat,
    longitude: lng,
    speed: speed,
  );
}

void main() {
  final start = DateTime.utc(2026, 10, 26, 10);

  group('TrackAnalytics.distanceMeters', () {
    test('is zero for fewer than two points', () {
      expect(TrackAnalytics.distanceMeters(const []), 0);
      expect(
        TrackAnalytics.distanceMeters([_entry('a', start, 50, 19)]),
        0,
      );
    });

    test('measures one degree of latitude as about 111 km', () {
      final distance = TrackAnalytics.distanceMeters([
        _entry('a', start, 50, 19),
        _entry('a', start.add(const Duration(hours: 1)), 51, 19),
      ]);

      expect(distance, closeTo(111195, 200));
    });

    test('shrinks a degree of longitude with the latitude', () {
      final distance = TrackAnalytics.distanceMeters([
        _entry('a', start, 60, 19),
        _entry('a', start.add(const Duration(hours: 1)), 60, 20),
      ]);

      expect(distance, closeTo(55597, 200));
    });

    test('adds consecutive legs', () {
      final entries = [
        _entry('a', start, 50, 19),
        _entry('a', start.add(const Duration(minutes: 1)), 50.001, 19),
        _entry('a', start.add(const Duration(minutes: 2)), 50.002, 19),
      ];

      expect(TrackAnalytics.distanceMeters(entries), closeTo(222.4, 1));
    });
  });

  group('TrackAnalytics.statsFor', () {
    test('computes duration, speed and pace of a steady walk', () {
      final entries = [
        for (var i = 0; i <= 10; i++)
          _entry(
            'a',
            start.add(Duration(seconds: i * 10)),
            50 + i * 0.0001,
            19,
          ),
      ];

      final stats = TrackAnalytics.statsFor(entries);

      expect(stats.distanceMeters, closeTo(111.2, 0.5));
      expect(stats.elapsed, const Duration(seconds: 100));
      expect(stats.movingTime, const Duration(seconds: 100));
      expect(stats.averageSpeedMps, closeTo(1.112, 0.01));
      expect(stats.pacePerKm!.inSeconds, closeTo(899, 5));
    });

    test('ignores long signal gaps when computing moving time', () {
      final entries = [
        _entry('a', start, 50, 19),
        _entry('a', start.add(const Duration(seconds: 30)), 50.0003, 19),
        _entry('a', start.add(const Duration(minutes: 40)), 50.0006, 19),
        _entry(
          'a',
          start.add(const Duration(minutes: 40, seconds: 30)),
          50.0009,
          19,
        ),
      ];

      final stats = TrackAnalytics.statsFor(entries);

      expect(stats.elapsed, const Duration(minutes: 40, seconds: 30));
      expect(stats.movingTime, const Duration(minutes: 1));
    });

    test('has no pace when nothing was covered', () {
      final stats = TrackAnalytics.statsFor([
        _entry('a', start, 50, 19),
        _entry('a', start.add(const Duration(minutes: 1)), 50, 19),
      ]);

      expect(stats.distanceMeters, 0);
      expect(stats.pacePerKm, isNull);
      expect(stats.averageSpeedMps, isNull);
    });

    test('is empty for no entries', () {
      final stats = TrackAnalytics.statsFor(const []);

      expect(stats.distanceMeters, 0);
      expect(stats.elapsed, Duration.zero);
    });
  });

  group('TrackAnalytics days', () {
    test('splitByDay uses the given UTC offset', () {
      final entries = [
        _entry('a', DateTime.utc(2026, 10, 26, 22, 30), 50, 19),
        _entry('a', DateTime.utc(2026, 10, 26, 23, 30), 50, 19),
        _entry('a', DateTime.utc(2026, 10, 27, 5), 50, 19),
      ];

      final days = TrackAnalytics.splitByDay(
        entries,
        utcOffset: const Duration(hours: 1),
      );

      expect(days.keys, [
        DateTime.utc(2026, 10, 26),
        DateTime.utc(2026, 10, 27),
      ]);
      expect(days[DateTime.utc(2026, 10, 26)]!.length, 1);
      expect(days[DateTime.utc(2026, 10, 27)]!.length, 2);
    });

    test('dailySummaries attribute a leg to the day it ended on', () {
      final entries = [
        _entry('a', DateTime.utc(2026, 10, 26, 23, 59, 30), 50, 19),
        _entry('a', DateTime.utc(2026, 10, 27, 0, 0, 30), 50.001, 19),
        _entry('a', DateTime.utc(2026, 10, 27, 0, 1, 30), 50.002, 19),
        _entry('b', DateTime.utc(2026, 10, 28, 12), 51, 20),
        _entry('b', DateTime.utc(2026, 10, 28, 12, 1), 51.001, 20),
      ];

      final summaries = TrackAnalytics.dailySummaries(
        entries,
        utcOffset: Duration.zero,
      );

      expect(summaries.map((s) => s.day), [
        DateTime.utc(2026, 10, 26),
        DateTime.utc(2026, 10, 27),
        DateTime.utc(2026, 10, 28),
      ]);
      expect(summaries[0].distanceMeters, 0);
      expect(summaries[1].distanceMeters, closeTo(222.4, 1));
      expect(summaries[2].distanceMeters, closeTo(111.2, 1));
      expect(summaries[1].sessionIds, {'a'});
      expect(summaries[2].sessionIds, {'b'});
      expect(summaries[1].pointCount, 2);
    });

    test('dailySummaries never connect different sessions', () {
      final entries = [
        _entry('a', start, 50, 19),
        _entry('b', start.add(const Duration(minutes: 5)), 52, 21),
      ];

      final summaries = TrackAnalytics.dailySummaries(
        entries,
        utcOffset: Duration.zero,
      );

      expect(summaries.single.distanceMeters, 0);
    });
  });
}
