import 'dart:async';

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

  /// Running while the press is younger than the shortest hold.
  Timer? _hold;
  bool _lifted = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _press() {
    _lifted = false;
    _hold?.cancel();
    _hold = Timer(context.motion.pressHold, () {
      _hold = null;
      if (mounted && _lifted) _setPressed(false);
    });
    _setPressed(true);
  }

  void _lift() {
    _lifted = true;
    if (_hold == null) _setPressed(false);
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final motion = context.motion;
    final content = Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Center(child: widget.child),
    );
    // A new fill, such as start turning into stop, blends in.
    final surface = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: widget.color ?? context.palette.background),
      duration: motion.short,
      curve: motion.curve,
      child: content,
      builder: (context, color, content) => TweenAnimationBuilder<double>(
        tween: Tween(end: _pressed ? 1 : 0),
        // It sinks in at once, as a tap is shorter than any animation; only
        // rising back can take time, as the motion says.
        duration: _pressed ? Duration.zero : motion.pressRise,
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
                  color: color,
                  size: widget.width,
                  padding: widget.padding,
                  child: content,
                )
              : NeuSurface(
                  shadows: shadows,
                  borderRadius: widget.borderRadius,
                  color: color,
                  width: widget.width,
                  height: widget.height,
                  padding: widget.padding,
                  child: content,
                );
        },
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => _press() : null,
        onTapUp: enabled ? (_) => _lift() : null,
        onTapCancel: enabled ? _lift : null,
        child: surface,
      ),
    );
  }
}
