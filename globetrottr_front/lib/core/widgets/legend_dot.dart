import 'package:flutter/material.dart';

/// A coloured dot in front of a label, as in a chart legend.
class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.child,
    this.size = 10,
    this.spacing = 6,
  });

  final Color color;
  final Widget child;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: spacing,
    children: [
      SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
      Flexible(child: child),
    ],
  );
}
