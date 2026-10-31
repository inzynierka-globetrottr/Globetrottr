import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

typedef FogMaskProvider = FogMask Function(FogTileId id);

/// Draws anti-aliased stadiums (a segment inflated by a radius) into tile
/// masks. Coordinates are world pixels at [zoom]; because Web Mercator is
/// conformal, a circle of meters stays a circle of pixels locally.
///
/// Interior pixels are filled with row spans, only the thin rim is computed
/// per pixel, so the cost follows the covered height and the rim length.
class FogRasterizer {
  const FogRasterizer({
    required this.zoom,
    this.edgeWidth = FogConfig.edgeWidthPixels,
    this.quantStep = 1,
  });

  final int zoom;

  /// Width of the anti-aliased ramp around the radius, in pixels.
  final double edgeWidth;

  /// Written values are rounded to multiples of this (0 and 255 stay). Using
  /// the step the tiles are stored with lets a redrawn pixel be compared with
  /// the stored one, so a pass that adds nothing is recognised as such.
  final int quantStep;

  void drawStadium({
    required double ax,
    required double ay,
    required double bx,
    required double by,
    required double radius,
    required FogMaskProvider maskFor,
    void Function(FogTileId id)? onChanged,
  }) {
    final shape = _Stadium(ax, ay, bx, by);
    final half = edgeWidth / 2;
    final outer = radius + half;
    final inner = radius - half;
    final tiles = 1 << zoom;
    const size = FogMask.size;

    final minX = math.min(ax, bx) - outer;
    final maxX = math.max(ax, bx) + outer;
    final minY = math.min(ay, by) - outer;
    final maxY = math.max(ay, by) + outer;

    final tileX0 = (minX / size).floor().clamp(0, tiles - 1);
    final tileX1 = (maxX / size).floor().clamp(0, tiles - 1);
    final tileY0 = (minY / size).floor().clamp(0, tiles - 1);
    final tileY1 = (maxY / size).floor().clamp(0, tiles - 1);

    for (var ty = tileY0; ty <= tileY1; ty++) {
      for (var tx = tileX0; tx <= tileX1; tx++) {
        final originX = tx * size;
        final originY = ty * size;
        final rowStart = math.max(minY.floor(), originY);
        final rowEnd = math.min(maxY.floor(), originY + size - 1);
        FogMask? mask;
        final id = FogTileId(zoom, tx, ty);
        var reported = false;

        for (var row = rowStart; row <= rowEnd; row++) {
          final yc = row + 0.5;
          if (!shape.scan(yc, outer)) continue;
          final outerFirst = math.max((shape.left - 0.5).ceil(), originX);
          final outerLast = math.min(
            (shape.right - 0.5).floor(),
            originX + size - 1,
          );
          if (outerFirst > outerLast) continue;

          var innerFirst = 1;
          var innerLast = 0;
          if (inner > 0 && shape.scan(yc, inner)) {
            innerFirst = (shape.left - 0.5).ceil();
            innerLast = (shape.right - 0.5).floor();
          }

          final data = (mask ??= maskFor(id)).data;
          final rowBase = (row - originY) * size - originX;
          var rowChanged = false;

          if (innerFirst <= innerLast) {
            final fillFrom = math.max(innerFirst, originX);
            final fillTo = math.min(innerLast, originX + size - 1);
            if (fillFrom <= fillTo) {
              rowChanged |= _fill(
                data,
                rowBase + fillFrom,
                rowBase + fillTo + 1,
              );
            }
            rowChanged |= _ramp(
              data,
              rowBase,
              shape,
              yc,
              radius + half,
              outerFirst,
              math.min(innerFirst - 1, outerLast),
            );
            rowChanged |= _ramp(
              data,
              rowBase,
              shape,
              yc,
              radius + half,
              math.max(innerLast + 1, outerFirst),
              outerLast,
            );
          } else {
            rowChanged |= _ramp(
              data,
              rowBase,
              shape,
              yc,
              radius + half,
              outerFirst,
              outerLast,
            );
          }
          if (rowChanged && !reported) {
            reported = true;
            onChanged?.call(id);
          }
        }
      }
    }
  }

  /// Fills [from, to) with 255; true when any pixel was not 255 already.
  static bool _fill(Uint8List data, int from, int to) {
    var changed = false;
    for (var i = from; i < to; i++) {
      if (data[i] != 255) {
        changed = true;
        break;
      }
    }
    if (changed) data.fillRange(from, to, 255);
    return changed;
  }

  int _quantize(int value) {
    if (quantStep <= 1 || value == 255) return value;
    final rounded = (value + quantStep ~/ 2) ~/ quantStep * quantStep;
    return rounded > 255 ? 255 : rounded;
  }

  bool _ramp(
    Uint8List data,
    int rowBase,
    _Stadium shape,
    double yc,
    double reach,
    int from,
    int to,
  ) {
    var changed = false;
    for (var x = from; x <= to; x++) {
      final distance = shape.distanceTo(x + 0.5, yc);
      final coverage = (reach - distance) / edgeWidth;
      if (coverage <= 0) continue;
      final value = _quantize(coverage >= 1 ? 255 : (coverage * 255).round());
      final index = rowBase + x;
      if (value > data[index]) {
        data[index] = value;
        changed = true;
      }
    }
    return changed;
  }
}

class _Stadium {
  _Stadium(this.ax, this.ay, this.bx, this.by) {
    final dx = bx - ax;
    final dy = by - ay;
    length = math.sqrt(dx * dx + dy * dy);
    lengthSquared = dx * dx + dy * dy;
    if (length > 1e-9) {
      directionX = dx / length;
      directionY = dy / length;
    }
  }

  final double ax;
  final double ay;
  final double bx;
  final double by;
  double length = 0;
  double lengthSquared = 0;
  double directionX = 0;
  double directionY = 0;

  /// Result of the last successful [scan].
  double left = 0;
  double right = 0;

  /// Finds where the horizontal line `y` crosses the shape inflated by
  /// [reach]. The capsule is convex, so the result is one interval.
  bool scan(double y, double reach) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;

    void disc(double cx, double cy) {
      final dy = y - cy;
      if (dy.abs() > reach) return;
      final w = math.sqrt(reach * reach - dy * dy);
      if (cx - w < lo) lo = cx - w;
      if (cx + w > hi) hi = cx + w;
    }

    void edge(double px, double py, double qx, double qy) {
      if ((py - y) * (qy - y) > 0 || py == qy) return;
      final x = px + (y - py) / (qy - py) * (qx - px);
      if (x < lo) lo = x;
      if (x > hi) hi = x;
    }

    disc(ax, ay);
    disc(bx, by);

    if (length > 1e-9) {
      final nx = -directionY * reach;
      final ny = directionX * reach;
      edge(ax + nx, ay + ny, bx + nx, by + ny);
      edge(ax - nx, ay - ny, bx - nx, by - ny);
      edge(ax + nx, ay + ny, ax - nx, ay - ny);
      edge(bx + nx, by + ny, bx - nx, by - ny);
    }

    if (lo > hi) return false;
    left = lo;
    right = hi;
    return true;
  }

  double distanceTo(double px, double py) {
    var t = 0.0;
    if (lengthSquared > 0) {
      t = (((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / lengthSquared)
          .clamp(0.0, 1.0);
    }
    final cx = ax + t * (bx - ax);
    final cy = ay + t * (by - ay);
    final dx = px - cx;
    final dy = py - cy;
    return math.sqrt(dx * dx + dy * dy);
  }
}
