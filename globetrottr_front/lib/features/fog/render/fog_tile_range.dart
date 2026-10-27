import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:meta/meta.dart';

/// A rectangular block of tiles on one level.
@immutable
class FogTileRange {
  const FogTileRange({
    required this.z,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  /// Whether [camera] has finite coordinates, zoom and a real size.
  ///
  /// The map can briefly report a camera that is not laid out yet or has
  /// received a NaN or infinite value; converting it to tile numbers with
  /// `floor()` or `round()` would throw an "Infinity or NaN toInt" error.
  static bool isUsable(MapCamera camera) {
    final size = camera.nonRotatedSize;
    final basics =
        camera.zoom.isFinite &&
        camera.center.latitude.isFinite &&
        camera.center.longitude.isFinite &&
        size.x.isFinite &&
        size.y.isFinite &&
        size.x > 0 &&
        size.y > 0;
    if (!basics) return false;
    final bounds = camera.visibleBounds;
    return bounds.south.isFinite &&
        bounds.north.isFinite &&
        bounds.west.isFinite &&
        bounds.east.isFinite;
  }

  /// The tiles that intersect the screen of [camera] on level [z].
  factory FogTileRange.visible(MapCamera camera, int z) {
    final bounds = camera.visibleBounds;
    final tiles = 1 << z;
    int tileOf(double worldPixel) =>
        (worldPixel / FogTileId.size).floor().clamp(0, tiles - 1);
    return FogTileRange(
      z: z,
      xMin: tileOf(FogMercator.lngToX(bounds.west, z)),
      xMax: tileOf(FogMercator.lngToX(bounds.east, z)),
      yMin: tileOf(FogMercator.latToY(bounds.north, z)),
      yMax: tileOf(FogMercator.latToY(bounds.south, z)),
    );
  }

  final int z;
  final int xMin;
  final int xMax;
  final int yMin;
  final int yMax;

  int get cellCount => (xMax - xMin + 1) * (yMax - yMin + 1);

  Iterable<FogTileId> get ids sync* {
    for (var y = yMin; y <= yMax; y++) {
      for (var x = xMin; x <= xMax; x++) {
        yield FogTileId(z, x, y);
      }
    }
  }

  bool contains(FogTileId id) =>
      id.z == z && id.x >= xMin && id.x <= xMax && id.y >= yMin && id.y <= yMax;

  FogTileRange expand(int by) {
    final last = (1 << z) - 1;
    return FogTileRange(
      z: z,
      xMin: (xMin - by).clamp(0, last),
      xMax: (xMax + by).clamp(0, last),
      yMin: (yMin - by).clamp(0, last),
      yMax: (yMax + by).clamp(0, last),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FogTileRange &&
      other.z == z &&
      other.xMin == xMin &&
      other.xMax == xMax &&
      other.yMin == yMin &&
      other.yMax == yMax;

  @override
  int get hashCode => Object.hash(z, xMin, xMax, yMin, yMax);

  @override
  String toString() => 'FogTileRange($z, x $xMin..$xMax, y $yMin..$yMax)';
}
