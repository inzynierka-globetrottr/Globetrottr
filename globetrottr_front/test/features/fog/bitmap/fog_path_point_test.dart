import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';

void main() {
  group('FogPathPoint.at', () {
    test('gives world pixels of the level', () {
      final point = FogPathPoint.at(krakowLat, krakowLng, 14);

      expect(point.x, FogMercator.lngToX(krakowLng, 14));
      expect(point.y, FogMercator.latToY(krakowLat, 14));
    });

    test('gives the vision radius in pixels at that latitude', () {
      final point = FogPathPoint.at(70, krakowLng, FogConfig.baseZoom);

      expect(
        point.radius,
        metersToPixels(
          meters: FogConfig.visionRadiusMeters,
          latitude: 70,
          zoom: FogConfig.baseZoom.toDouble(),
        ),
      );
    });
  });
}
