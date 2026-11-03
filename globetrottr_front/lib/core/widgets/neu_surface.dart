import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// The building block of every neumorphic element: a filled shape with the
/// design's shadows. Outer shadows are drawn behind it, inset shadows inside
/// it, under [child].
class NeuSurface extends StatelessWidget {
  const NeuSurface({
    super.key,
    required this.shadows,
    required this.borderRadius,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.child,
  }) : _circle = false;

  const NeuSurface.circle({
    super.key,
    required this.shadows,
    this.color,
    double? size,
    this.padding,
    this.child,
  }) : borderRadius = null,
       width = size,
       height = size,
       _circle = true;

  final List<NeoShadow> shadows;
  final BorderRadius? borderRadius;

  /// Defaults to the page colour.
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final bool _circle;

  @override
  Widget build(BuildContext context) {
    final inset = [
      for (final s in shadows)
        if (s.inset) s,
    ];
    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    if (inset.isNotEmpty) {
      content = NeuInsetShadow(
        shadows: inset,
        borderRadius: borderRadius,
        circle: _circle,
        child: content,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? context.palette.background,
          shape: _circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
          boxShadow: [
            for (final s in shadows)
              if (!s.inset) s.toBoxShadow(),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// Paints inset shadows inside a rounded rectangle or a circle, behind
/// [child].
class NeuInsetShadow extends StatelessWidget {
  const NeuInsetShadow({
    super.key,
    required this.shadows,
    this.borderRadius,
    this.circle = false,
    this.child,
  });

  final List<NeoShadow> shadows;
  final BorderRadius? borderRadius;
  final bool circle;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _InsetShadowPainter(shadows, borderRadius, circle),
    child: child,
  );
}

class _InsetShadowPainter extends CustomPainter {
  _InsetShadowPainter(this.shadows, this.borderRadius, this.circle);

  final List<NeoShadow> shadows;
  final BorderRadius? borderRadius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final shape = circle
        ? (Path()..addOval(bounds))
        : (Path()
            ..addRRect((borderRadius ?? BorderRadius.zero).toRRect(bounds)));
    canvas
      ..save()
      ..clipPath(shape);
    for (final shadow in shadows) {
      // Everything outside the shape, shifted by the offset, casts the
      // shadow; the clip keeps the part that falls inside.
      final margin = shadow.blur * 2 + shadow.offset.distance;
      final caster = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(margin))
        ..addPath(shape, shadow.offset);
      canvas.drawPath(
        caster,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.sigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter old) =>
      !listEquals(old.shadows, shadows) ||
      old.borderRadius != borderRadius ||
      old.circle != circle;
}
