import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';
import '../../../support/explorer_route_generator.dart';

TrackLogEntry _entry(
  int ts, {
  double lat = 50.0614,
  double lng = 19.9383,
  double? accuracy,
  double? speed,
  String session = 's',
}) {
  return TrackLogEntry(
    sessionId: session,
    timestampMs: ts,
    latitude: lat,
    longitude: lng,
    accuracy: accuracy,
    speed: speed,
  );
}

void _expectSame(TrackLogEntry actual, TrackLogEntry expected) {
  expect(actual.sessionId, expected.sessionId);
  expect(actual.id, expected.id);
  expect(actual.timestampMs, expected.timestampMs);
  expect(actual.latitude, expected.latitude);
  expect(actual.longitude, expected.longitude);
  expect(actual.accuracy, expected.accuracy);
  expect(actual.speed, expected.speed);
}

void main() {
  group('TrackBlockCodec.quantize', () {
    test('rounds a position to a hundred-millionth of a degree', () {
      final q = TrackBlockCodec.quantize(
        _entry(1, lat: 50.061412349, lng: 19.938312351),
      );

      expect(q.latitude, 50.0614123);
      expect(q.longitude, 19.9383124);
    });

    test('rounds accuracy to 0.1 m and speed to 0.01 m/s', () {
      final q = TrackBlockCodec.quantize(
        _entry(1, accuracy: 4.5678, speed: 1.2345),
      );

      expect(q.accuracy, 4.6);
      expect(q.speed, 1.23);
    });

    test('keeps the session, id and time', () {
      final q = TrackBlockCodec.quantize(
        const TrackLogEntry(
          id: 7,
          sessionId: 'abc',
          timestampMs: 1700000000123,
          latitude: 1,
          longitude: 2,
        ),
      );

      expect(q.id, 7);
      expect(q.sessionId, 'abc');
      expect(q.timestampMs, 1700000000123);
    });

    test('keeps missing accuracy and speed missing', () {
      final q = TrackBlockCodec.quantize(_entry(1));

      expect(q.accuracy, isNull);
      expect(q.speed, isNull);
    });

    test('treats a negative accuracy or speed as unknown', () {
      final q = TrackBlockCodec.quantize(_entry(1, accuracy: -1, speed: -0.5));

      expect(q.accuracy, isNull);
      expect(q.speed, isNull);
    });

    test('is idempotent', () {
      final once = TrackBlockCodec.quantize(
        _entry(
          1,
          lat: 50.123456789,
          lng: 19.987654321,
          accuracy: 3.14159,
          speed: 2.71828,
        ),
      );

      final twice = TrackBlockCodec.quantize(once);

      _expectSame(twice, once);
    });

    test('keeps ordinary coordinates exactly as they are written', () {
      final q = TrackBlockCodec.quantize(_entry(1, lat: 50.1, lng: 19.2));

      expect(q.latitude, 50.1);
      expect(q.longitude, 19.2);
    });

    test('refuses a position that is not a real number', () {
      expect(
        () => TrackBlockCodec.quantize(_entry(1, lat: double.nan)),
        throwsArgumentError,
      );
      expect(
        () => TrackBlockCodec.quantize(_entry(1, lng: double.infinity)),
        throwsArgumentError,
      );
    });
  });

  group('TrackBlockCodec round trip', () {
    List<TrackLogEntry> decode(
      Uint8List bytes,
      int count, {
      int firstId = 41,
    }) => TrackBlockCodec.decode(bytes, sessionId: 's', firstId: firstId);

    test('restores a single point', () {
      final source = [_entry(1700000000000, accuracy: 5, speed: 1.5)];

      final restored = decode(TrackBlockCodec.encode(source), 1);

      expect(restored.length, 1);
      _expectSame(
        restored.single,
        TrackBlockCodec.quantize(source.single).withId(41),
      );
    });

    test('restores an empty block', () {
      expect(decode(TrackBlockCodec.encode(const []), 0), isEmpty);
    });

    test('numbers the points from the first id', () {
      final source = [for (var i = 0; i < 5; i++) _entry(1000 + i)];

      final restored = decode(TrackBlockCodec.encode(source), 5, firstId: 100);

      expect(restored.map((e) => e.id), [100, 101, 102, 103, 104]);
    });

    test('restores a walk including moves west and south', () {
      final source = [
        for (var i = 0; i < 300; i++)
          _entry(
            1700000000000 + i * 1000,
            lat: 50.0 - i * 0.00009,
            lng: 19.0 - i * 0.00013,
            accuracy: 3 + (i % 7) * 0.5,
            speed: 1.2 + (i % 5) * 0.01,
          ),
      ];

      final restored = decode(TrackBlockCodec.encode(source), 300);

      expect(restored.length, 300);
      for (var i = 0; i < 300; i++) {
        _expectSame(
          restored[i],
          TrackBlockCodec.quantize(source[i]).withId(41 + i),
        );
      }
    });

    test('restores missing and present accuracy and speed mixed', () {
      final source = [
        _entry(1),
        _entry(2, accuracy: 4.2),
        _entry(3, speed: 0),
        _entry(4, accuracy: 0, speed: 3.33),
        _entry(5),
      ];

      final restored = decode(TrackBlockCodec.encode(source), 5);

      expect(restored.map((e) => e.accuracy), [null, 4.2, null, 0.0, null]);
      expect(restored.map((e) => e.speed), [null, null, 0.0, 3.33, null]);
    });

    test('restores very large jumps between points', () {
      final source = [
        _entry(1, lat: -85, lng: -179.9999999),
        _entry(2, lat: 85, lng: 179.9999999),
        _entry(3, lat: 0, lng: 0),
      ];

      final restored = decode(TrackBlockCodec.encode(source), 3);

      expect(restored.map((e) => e.latitude), [-85.0, 85.0, 0.0]);
      expect(restored.map((e) => e.longitude), [
        -179.9999999,
        179.9999999,
        0.0,
      ]);
    });

    test('restores times that do not increase', () {
      final source = [_entry(5000), _entry(3000), _entry(9000), _entry(9000)];

      final restored = decode(TrackBlockCodec.encode(source), 4);

      expect(restored.map((e) => e.timestampMs), [5000, 3000, 9000, 9000]);
    });

    test('is deterministic', () {
      final source = [
        for (var i = 0; i < 50; i++) _entry(i * 1000, lat: 50 + i * 1e-5),
      ];

      expect(TrackBlockCodec.encode(source), TrackBlockCodec.encode(source));
    });
  });

  group('TrackBlockCodec format', () {
    test('starts with a format version', () {
      final bytes = TrackBlockCodec.encode([_entry(1)]);

      expect(bytes.first, TrackBlockCodec.formatVersion);
    });

    test('rejects an unknown version', () {
      final bytes = TrackBlockCodec.encode([_entry(1)]);
      bytes[0] = 99;

      expect(
        () => TrackBlockCodec.decode(bytes, sessionId: 's', firstId: 1),
        throwsFormatException,
      );
    });

    test('rejects data that is not a block', () {
      expect(
        () => TrackBlockCodec.decode(
          Uint8List.fromList([TrackBlockCodec.formatVersion, 1, 2, 3, 4]),
          sessionId: 's',
          firstId: 1,
        ),
        throwsA(anything),
      );
    });

    test('a block of a real walk takes only a few bytes per point', () {
      final journey = ExplorerRouteGenerator.generate(
        start: const LatLng(50.0614, 19.9383),
        totalKm: 40,
      );
      final session = journey.where(
        (e) => e.sessionId == journey.first.sessionId,
      );
      final points = session.take(500).toList();

      final bytes = TrackBlockCodec.encode(points);

      expect(points.length, 500);
      expect(bytes.length / points.length, lessThan(8));
    });

    test('the bounds cover every point of a block', () {
      final source = [
        _entry(1, lat: 50.2, lng: 19.5),
        _entry(2, lat: 49.9, lng: 19.9),
        _entry(3, lat: 50.4, lng: 19.1),
      ];

      final bounds = TrackBlockCodec.boundsOf(source);

      expect(bounds.south, 49.9);
      expect(bounds.north, 50.4);
      expect(bounds.west, 19.1);
      expect(bounds.east, 19.9);
    });

    test('the time range covers every point of a block', () {
      final range = TrackBlockCodec.timeRangeOf([
        _entry(5),
        _entry(2),
        _entry(9),
      ]);

      expect(range.start, 2);
      expect(range.end, 9);
    });
  });
}
