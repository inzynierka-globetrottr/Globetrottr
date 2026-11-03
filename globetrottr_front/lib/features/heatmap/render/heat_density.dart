import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';

/// How a density image is computed: the blur and how density maps to the
/// colour scale. Only numbers and typed data, so it can go to an isolate.
class HeatDensityRecipe {
  const HeatDensityRecipe({
    required this.boxRadius,
    required this.unit,
    required this.saturation,
    this.contrast = 1,
    required this.levels,
  });

  /// Radius in tile pixels of each of the three box blurs, which together
  /// approximate a Gaussian of sigma `boxRadius` (on any zoom level, so the
  /// patches keep their size on the screen).
  final int boxRadius;

  /// Density that is told apart from nothing: a route passed once.
  final double unit;

  /// Density that reaches the end of the scale.
  final double saturation;

  /// Exponent of the curve along the scale: above 1 most of the traffic
  /// stays dark and only the busiest places reach the end.
  final double contrast;

  /// The premultiplied RGBA word of every step 0..255 of the scale.
  final Uint32List levels;

  /// How far the blur reaches out of a tile, in pixels.
  int get reach => 3 * boxRadius + 1;
}

/// Turns the session counts around a tile into the pixels of its image (the
/// layout of [FogTilePixels]): the counts are blurred into a density, which
/// then picks a colour of the scale on a logarithmic curve.
///
/// `around` holds the counts of the tile and its eight neighbours, row by
/// row from the north-west; null is a tile without data. Neighbours matter
/// because the blur spreads across tile borders.
abstract final class HeatDensity {
  static Uint8List build(List<Uint8List?> around, HeatDensityRecipe recipe) {
    const size = FogMask.size;
    final margin = recipe.reach;
    final side = size + 2 * margin;
    var field = Float32List(side * side);
    var spare = Float32List(side * side);

    var any = false;
    for (var y = 0; y < side; y++) {
      final wy = y - margin;
      final ty = wy < 0 ? 0 : (wy >= size ? 2 : 1);
      final py = wy - (ty - 1) * size;
      for (var x = 0; x < side; x++) {
        final wx = x - margin;
        final tx = wx < 0 ? 0 : (wx >= size ? 2 : 1);
        final counts = around[ty * 3 + tx];
        if (counts == null) continue;
        final px = wx - (tx - 1) * size;
        final value = counts[py * size + px];
        if (value == 0) continue;
        field[y * side + x] = value.toDouble();
        any = true;
      }
    }

    final pixels = Uint32List(FogTilePixels.side * FogTilePixels.side);
    if (!any) return pixels.buffer.asUint8List();

    for (var pass = 0; pass < 3; pass++) {
      _blurRows(field, spare, side, recipe.boxRadius);
      final swap = field;
      field = spare;
      spare = swap;
    }
    for (var pass = 0; pass < 3; pass++) {
      _blurColumns(field, spare, side, recipe.boxRadius);
      final swap = field;
      field = spare;
      spare = swap;
    }

    final top = math.log(1 + recipe.saturation / recipe.unit);
    // The running sums leave rounding residue where there is nothing.
    final floor = recipe.unit * 0.02;
    const out = FogTilePixels.side;
    for (var y = 0; y < out; y++) {
      final row = (y - 1 + margin) * side + margin - 1;
      for (var x = 0; x < out; x++) {
        final density = field[row + x];
        if (density < floor) continue;
        final share = math.pow(
          math.log(1 + density / recipe.unit) / top,
          recipe.contrast,
        );
        pixels[y * out + x] =
            recipe.levels[(share.clamp(0.0, 1.0) * 255).round()];
      }
    }
    return pixels.buffer.asUint8List();
  }

  /// A box average along every row, with zeros outside the grid.
  static void _blurRows(Float32List from, Float32List to, int side, int r) {
    final width = 2 * r + 1;
    for (var y = 0; y < side; y++) {
      final row = y * side;
      var sum = 0.0;
      for (var x = 0; x < r && x < side; x++) {
        sum += from[row + x];
      }
      for (var x = 0; x < side; x++) {
        final enter = x + r;
        if (enter < side) sum += from[row + enter];
        final leave = x - r - 1;
        if (leave >= 0) sum -= from[row + leave];
        to[row + x] = sum / width;
      }
    }
  }

  /// A box average along every column, with zeros outside the grid.
  static void _blurColumns(Float32List from, Float32List to, int side, int r) {
    final width = 2 * r + 1;
    for (var x = 0; x < side; x++) {
      var sum = 0.0;
      for (var y = 0; y < r && y < side; y++) {
        sum += from[y * side + x];
      }
      for (var y = 0; y < side; y++) {
        final enter = y + r;
        if (enter < side) sum += from[enter * side + x];
        final leave = y - r - 1;
        if (leave >= 0) sum -= from[leave * side + x];
        to[y * side + x] = sum / width;
      }
    }
  }
}
