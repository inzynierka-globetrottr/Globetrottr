import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A ring around [child] filled clockwise from the top by [fill] (0 to 1).
/// Its radius and stroke are fractions of the widget's width, so it scales
/// with the circle it sits in. A changed fill is reached gradually.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fill,
    required this.color,
    required this.radiusRatio,
    required this.strokeRatio,
    this.trackColor,
    this.child,
  });

  final double fill;
  final Color color;
  final double radiusRatio;
  final double strokeRatio;

  /// The unfilled part of the ring; not drawn when null.
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fill),
      duration: motion.long,
      curve: motion.curve,
      child: child,
      builder: (context, shown, child) => CustomPaint(
        painter: _RingPainter(
          fill: shown,
          color: color,
          trackColor: trackColor,
          radiusRatio: radiusRatio,
          strokeRatio: strokeRatio,
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fill,
    required this.color,
    required this.trackColor,
    required this.radiusRatio,
    required this.strokeRatio,
  });

  final double fill;
  final Color color;
  final Color? trackColor;
  final double radiusRatio;
  final double strokeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width * radiusRatio,
    );
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * strokeRatio
      ..strokeCap = StrokeCap.round;

    if (trackColor != null) canvas.drawOval(rect, stroke(trackColor!));
    if (fill <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fill.clamp(0, 1),
      false,
      stroke(color),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.radiusRatio != radiusRatio ||
      old.strokeRatio != strokeRatio;
}
