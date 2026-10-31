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

  /// The tiles under a box of world pixels at level [z], cut to the world.
  factory FogTileRange.covering({
    required int z,
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) {
    final last = (1 << z) - 1;
    return FogTileRange(
      z: z,
      xMin: _tileOf(minX, last),
      xMax: _tileOf(maxX, last),
      yMin: _tileOf(minY, last),
      yMax: _tileOf(maxY, last),
    );
  }

  static int _tileOf(double worldPixel, int last) {
    return (worldPixel / FogTileId.size).floor().clamp(0, last);
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
