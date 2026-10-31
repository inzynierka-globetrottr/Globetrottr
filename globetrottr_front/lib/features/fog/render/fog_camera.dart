import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';

/// What the fog needs to know about the map camera.
extension FogCamera on MapCamera {
  /// Whether the camera has finite coordinates, zoom and a real size.
  ///
  /// The map can briefly report a camera that is not laid out yet or has
  /// received a NaN or infinite value; converting it to tile numbers with
  /// `floor()` or `round()` would throw an "Infinity or NaN toInt" error.
  bool get isUsableForFog {
    final size = nonRotatedSize;
    final basics =
        zoom.isFinite &&
        center.latitude.isFinite &&
        center.longitude.isFinite &&
        size.x.isFinite &&
        size.y.isFinite &&
        size.x > 0 &&
        size.y > 0;
    if (!basics) return false;
    final bounds = visibleBounds;
    return bounds.south.isFinite &&
        bounds.north.isFinite &&
        bounds.west.isFinite &&
        bounds.east.isFinite;
  }

  /// The tiles that intersect the screen on level [z].
  FogTileRange visibleTiles(int z) {
    final bounds = visibleBounds;
    return FogTileRange.covering(
      z: z,
      minX: FogMercator.lngToX(bounds.west, z),
      maxX: FogMercator.lngToX(bounds.east, z),
      minY: FogMercator.latToY(bounds.north, z),
      maxY: FogMercator.latToY(bounds.south, z),
    );
  }
}
