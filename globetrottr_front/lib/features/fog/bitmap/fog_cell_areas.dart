import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

/// Ground area per cell of a base tile: the 256 x 256 pixels split into
/// 16 x 16 cells of 16 x 16 pixels (about 50 m at z15), row by row. Lets the
/// statistics follow region borders inside a tile.
class FogCellAreas {
  FogCellAreas(this.values)
    : assert(values.length == count, 'A tile has exactly $count cells');

  static const int side = 16;
  static const int count = side * side;
  static const int pixelsPerCell = 16;

  /// Cell areas of a mask from its `FogMask.cellSums`.
  factory FogCellAreas.ofSums(FogTileId id, Int32List sums) {
    final pixelArea = pixelAreaM2(id);
    return FogCellAreas(
      Float32List.fromList([for (final s in sums) s / 255.0 * pixelArea]),
    );
  }

  /// Ground area of one pixel of tile [id], taken at the tile's middle.
  static double pixelAreaM2(FogTileId id) {
    final latitude = FogMercator.yToLat((id.y + 0.5) * FogTileId.size, id.z);
    final pixel = metersPerPixel(latitude: latitude, zoom: id.z.toDouble());
    return pixel * pixel;
  }

  /// Square metres per cell.
  final Float32List values;

  double get total {
    var sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    return sum;
  }
}
