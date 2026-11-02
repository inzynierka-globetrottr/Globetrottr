import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// What a round button is filled with.
enum NeuFill { page, accent, danger }

/// A round raised button holding an icon.
class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 46,
    this.depth = NeoDepth.sm,
    this.fill = NeuFill.page,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final NeoDepth depth;
  final NeuFill fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    return NeuPressable(
      onPressed: onPressed,
      shadows: fill == NeuFill.page
          ? shadows.raised(depth)
          : shadows.raisedAccent(depth),
      depth: NeoDepth.xs,
      width: size,
      color: switch (fill) {
        NeuFill.page => null,
        NeuFill.accent => palette.accent,
        NeuFill.danger => palette.danger,
      },
      semanticLabel: semanticLabel,
      child: IconTheme.merge(
        data: IconThemeData(
          color: fill == NeuFill.page ? palette.text : palette.onAccent,
          size: 18,
        ),
        child: child,
      ),
    );
  }
}
