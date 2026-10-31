import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws stadiums as brightness with exactly the soft edge the rasterizer
/// stores in the tiles: the full value up to `radius - rim / 2`, falling in a
/// straight line to nothing at `radius + rim / 2`.
///
/// A stadium is a rectangle with a gradient across it and a disc with a
/// radial gradient at each end. Each piece is the distance to the segment in
/// its own area, and [BlendMode.lighten] keeps the larger value, so together
/// they are the same field as the tiles. On opaque colours `lighten` is a true
/// maximum per pixel, the same way tiles are merged.
class FogLiveShapes {
  FogLiveShapes(
    this.canvas,
    this.view, {
    required this.radius,
    required this.rim,
    required double value,
  }) : _full = Color.from(alpha: 1, red: value, green: value, blue: value);

  final Canvas canvas;
  final Rect view;
  final double radius;
  final double rim;
  final Color _full;

  double get _outer => radius + rim / 2;
  double get _inner => math.max(0, radius - rim / 2);

  Offset? _lastEnd;

  void add(Offset a, Offset b) {
    if (!Rect.fromPoints(a, b).inflate(_outer).overlaps(view)) {
      _lastEnd = null;
      return;
    }
    if (a != _lastEnd) _disc(a);
    if (b != a) {
      _disc(b);
      _band(a, b);
    }
    _lastEnd = b;
  }

  void _disc(Offset center) {
    canvas.drawCircle(
      center,
      _outer,
      Paint()
        ..blendMode = BlendMode.lighten
        ..shader = ui.Gradient.radial(
          center,
          _outer,
          [_full, _full, Colors.black],
          [0, _inner / _outer, 1],
        ),
    );
  }

  void _band(Offset a, Offset b) {
    final along = b - a;
    final edge = (_outer - _inner) / (2 * _outer);
    canvas
      ..save()
      ..translate(a.dx, a.dy)
      ..rotate(along.direction)
      ..drawRect(
        Rect.fromLTRB(0, -_outer, along.distance, _outer),
        Paint()
          ..blendMode = BlendMode.lighten
          ..shader = ui.Gradient.linear(
            Offset(0, -_outer),
            Offset(0, _outer),
            [Colors.black, _full, _full, Colors.black],
            [0, edge, 1 - edge, 1],
          ),
      )
      ..restore();
  }
}
