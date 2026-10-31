import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

/// A point of a path in world pixels, with the vision radius in pixels at its
/// latitude. Live drawing, imports and the trail all get their points from
/// [FogPathPoint.at], so they cannot disagree on where a position lands.
class FogPathPoint {
  const FogPathPoint(this.x, this.y, this.radius);

  factory FogPathPoint.at(double latitude, double longitude, int zoom) {
    return FogPathPoint(
      FogMercator.lngToX(longitude, zoom),
      FogMercator.latToY(latitude, zoom),
      metersToPixels(
        meters: FogConfig.visionRadiusMeters,
        latitude: latitude,
        zoom: zoom.toDouble(),
      ),
    );
  }

  final double x;
  final double y;
  final double radius;
}
