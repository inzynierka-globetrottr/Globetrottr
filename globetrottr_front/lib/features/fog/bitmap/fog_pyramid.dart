import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';

/// Builds coarser tiles from finer ones for displaying the fog zoomed out.
///
/// A plain average would make a 60 m road vanish on a country-sized view, so
/// on the levels where a road is thinner than a few pixels a coarse pixel is
/// the larger of the average and the strongest child pixel capped at
/// [defaultOverviewFloor]. Capping (instead of scaling) means a thin road
/// keeps the same visibility on every level instead of decaying. An
/// `overviewFloor` of 0 leaves the plain average, which keeps the fog edge in
/// place between levels.
abstract final class FogPyramid {
  static const int defaultOverviewFloor = 144;

  /// Overwrites quadrant ([quadX], [quadY]) of [parent] with [child] halved.
  static void downsampleInto({
    required FogMask child,
    required FogMask parent,
    required int quadX,
    required int quadY,
    int overviewFloor = defaultOverviewFloor,
  }) {
    const size = FogMask.size;
    const half = size ~/ 2;
    final source = child.data;
    final target = parent.data;
    final originX = quadX * half;
    final originY = quadY * half;

    for (var y = 0; y < half; y++) {
      final upper = (2 * y) * size;
      final lower = upper + size;
      final targetRow = (originY + y) * size + originX;
      for (var x = 0; x < half; x++) {
        final i = upper + 2 * x;
        final j = lower + 2 * x;
        final a = source[i];
        final b = source[i + 1];
        final c = source[j];
        final d = source[j + 1];

        final average = (a + b + c + d + 2) >> 2;
        var strongest = a > b ? a : b;
        if (c > strongest) strongest = c;
        if (d > strongest) strongest = d;
        if (strongest > overviewFloor) strongest = overviewFloor;

        target[targetRow + x] = average > strongest ? average : strongest;
      }
    }
  }
}
