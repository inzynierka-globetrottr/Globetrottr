import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart'
    show FogMercator;
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';

({double x, double y, double radius}) _pixel(double lat, double lng) {
  const zoom = FogConfig.baseZoom;
  return (
    x: FogMercator.lngToX(lng, zoom),
    y: FogMercator.latToY(lat, zoom),
    radius: metersToPixels(
      meters: FogConfig.visionRadiusMeters,
      latitude: lat,
      zoom: zoom.toDouble(),
    ),
  );
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
    return rule.connects(a.x, a.y, b.x, b.y, b.radius);
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

    test('connects a point with itself', () {
      expect(connectsAfter(krakowLat, krakowLng), isTrue);
    });
  });
}
