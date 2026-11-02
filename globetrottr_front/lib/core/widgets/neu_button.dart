import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// A secondary action: a raised pill in the page colour.
class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.depth = NeoDepth.lg,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final NeoDepth depth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => NeuPressable(
    onPressed: onPressed,
    shadows: context.shadows.raised(depth),
    depth: NeoDepth.sm,
    width: width,
    height: height,
    borderRadius: BorderRadius.circular(height / 2),
    padding: padding,
    child: DefaultTextStyle.merge(
      style: context.typography.itemTitle,
      child: child,
    ),
  );
}
