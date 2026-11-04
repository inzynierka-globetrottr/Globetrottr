import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// How small a dialog starts before it grows to its size.
const _dialogStartScale = 0.95;

/// How much the page behind an open dialog is dimmed.
const _barrierAlpha = 0.5;

/// Shows a dialog that fades in while growing a little. Tapping outside
/// closes it.
Future<T?> showNeuDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final motion = context.motion;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.palette.shadowOverlay.withValues(
      alpha: _barrierAlpha,
    ),
    transitionDuration: motion.short,
    pageBuilder: (context, _, _) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (context, animation, _, child) {
      final curved = animation.drive(CurveTween(curve: motion.curve));
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: _dialogStartScale, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
