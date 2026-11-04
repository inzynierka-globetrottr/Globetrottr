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
    this.overMap = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final NeoDepth depth;
  final NeuFill fill;
  final String? semanticLabel;

  /// Floats over a map and casts the map controls' shadow instead of
  /// [depth].
  final bool overMap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    final (color, iconColor) = switch (fill) {
      NeuFill.page => (null, palette.text),
      NeuFill.accent => (palette.accent, palette.onAccent),
      NeuFill.danger => (palette.danger, palette.onAccent),
    };
    final page = fill == NeuFill.page;
    return NeuPressable(
      onPressed: onPressed,
      shadows: overMap
          ? shadows.mapControl
          : page
          ? shadows.raised(depth)
          : shadows.raisedAccent(depth),
      pressedShadows: page
          ? shadows.inset(NeoDepth.xs)
          : shadows.insetAccent(NeoDepth.xs),
      width: size,
      color: color,
      semanticLabel: semanticLabel,
      child: IconTheme.merge(
        data: IconThemeData(color: iconColor, size: 18),
        child: child,
      ),
    );
  }
}
