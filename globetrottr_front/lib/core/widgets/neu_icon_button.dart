import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// A round raised button holding an icon.
class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 46,
    this.depth = NeoDepth.sm,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final NeoDepth depth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => NeuPressable(
    onPressed: onPressed,
    shadows: context.shadows.raised(depth),
    depth: NeoDepth.xs,
    width: size,
    semanticLabel: semanticLabel,
    child: IconTheme.merge(
      data: IconThemeData(color: context.palette.text, size: 18),
      child: child,
    ),
  );
}
