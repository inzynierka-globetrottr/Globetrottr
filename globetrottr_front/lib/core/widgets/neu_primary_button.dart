import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// The main action of a screen: a full-width pill filled with the accent.
/// While [isLoading] it shows progress instead of the label and ignores taps.
class NeuPrimaryButton extends StatelessWidget {
  const NeuPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  static const _height = 60.0;
  static const _progressSize = 22.0;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeuPressable(
      onPressed: isLoading ? () {} : onPressed,
      shadows: context.shadows.raisedAccent(NeoDepth.xl),
      pressedShadows: context.shadows.insetAccent(NeoDepth.md),
      color: palette.accent,
      width: double.infinity,
      height: _height,
      borderRadius: BorderRadius.circular(_height / 2),
      semanticLabel: label,
      child: isLoading
          ? SizedBox.square(
              dimension: _progressSize,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.onAccent,
              ),
            )
          : Text(label, style: context.typography.button),
    );
  }
}
