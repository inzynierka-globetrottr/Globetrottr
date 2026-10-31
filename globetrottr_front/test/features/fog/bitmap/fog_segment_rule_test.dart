import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';

FogPathPoint _pixel(double lat, double lng) {
  return FogPathPoint.at(lat, lng, FogConfig.baseZoom);
}

void main() {
  const rule = FogSegmentRule(
    radiusMeters: FogConfig.visionRadiusMeters,
    maxSegmentMeters: 350,
  );

  bool connectsAfter(
    double lat,
    double lng, {
    double north = 0,
    double east = 0,
  }) {
    final a = _pixel(lat, lng);
    final end = offsetMeters(lat, lng, north: north, east: east);
    final b = _pixel(end.lat, end.lng);
    return rule.connects(a, b);
  }

  group('FogSegmentRule', () {
    test('connects points closer than the limit', () {
      expect(connectsAfter(krakowLat, krakowLng, east: 10), isTrue);
      expect(connectsAfter(krakowLat, krakowLng, east: 340), isTrue);
    });

    test('breaks the path beyond the limit', () {
      expect(connectsAfter(krakowLat, krakowLng, east: 360), isFalse);
      expect(connectsAfter(krakowLat, krakowLng, north: 5000), isFalse);
    });

    test('measures real meters at every latitude', () {
      for (final lat in [0.0, 50.0, 70.0]) {
        expect(connectsAfter(lat, 19, north: 340), isTrue);
        expect(connectsAfter(lat, 19, east: 340), isTrue);
        expect(connectsAfter(lat, 19, north: 360), isFalse);
        expect(connectsAfter(lat, 19, east: 360), isFalse);
      }
    });

    test('breaks a path whose tiles exceed the safety cap', () {
      const loose = FogSegmentRule(
        radiusMeters: FogConfig.visionRadiusMeters,
        maxSegmentMeters: 1000000,
      );
      final a = _pixel(krakowLat, krakowLng);
      final near = offsetMeters(krakowLat, krakowLng, north: 1000, east: 1000);
      final far = offsetMeters(krakowLat, krakowLng, north: 5000, east: 5000);

      expect(loose.connects(a, _pixel(near.lat, near.lng)), isTrue);
      expect(loose.connects(a, _pixel(far.lat, far.lng)), isFalse);
    });

    test('the cap never cuts a segment within the meter limit', () {
      for (final lat in [0.0, 50.0, 70.0, 80.0]) {
        for (final direction in [(1.0, 0.0), (0.0, 1.0), (0.7, 0.7)]) {
          expect(
            connectsAfter(
              lat,
              19,
              north: 340 * direction.$1,
              east: 340 * direction.$2,
            ),
            isTrue,
            reason: 'latitude $lat, direction $direction',
          );
        }
      }
    });

    test('connects a point with itself', () {
      expect(connectsAfter(krakowLat, krakowLng), isTrue);
    });
  });
}
