import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A raised surface that sinks in while pressed. The common part of every
/// neumorphic button; a disabled one ([onPressed] null) is dimmed.
class NeuPressable extends StatefulWidget {
  const NeuPressable({
    super.key,
    required this.onPressed,
    required this.shadows,
    required this.pressedShadows,
    required this.child,
    this.color,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;

  /// Shadows while not pressed.
  final List<NeoShadow> shadows;

  /// Shadows while pressed.
  final List<NeoShadow> pressedShadows;
  final Widget child;
  final Color? color;
  final double? width;
  final double? height;

  /// A circle when null.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  State<NeuPressable> createState() => _NeuPressableState();
}

class _NeuPressableState extends State<NeuPressable> {
  static const _disabledOpacity = 0.5;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final motion = context.motion;
    final content = Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Center(child: widget.child),
    );
    final surface = TweenAnimationBuilder<double>(
      tween: Tween(end: _pressed ? 1 : 0),
      duration: motion.short,
      curve: motion.curve,
      child: content,
      builder: (context, depth, content) {
        final shadows = lerpShadows(
          widget.shadows,
          widget.pressedShadows,
          depth,
        );
        return widget.borderRadius == null
            ? NeuSurface.circle(
                shadows: shadows,
                color: widget.color,
                size: widget.width,
                padding: widget.padding,
                child: content,
              )
            : NeuSurface(
                shadows: shadows,
                borderRadius: widget.borderRadius,
                color: widget.color,
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                child: content,
              );
      },
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: surface,
      ),
    );
  }
}
