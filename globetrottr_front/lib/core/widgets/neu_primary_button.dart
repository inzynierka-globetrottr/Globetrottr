import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

enum NeuPrimarySize {
  /// The main action of a screen.
  large(60, NeoDepth.xl, NeoDepth.md),

  /// The action of a card or a dialog.
  medium(48, NeoDepth.md, NeoDepth.sm);

  const NeuPrimarySize(this.height, this.depth, this.pressedDepth);

  final double height;
  final NeoDepth depth;
  final NeoDepth pressedDepth;
}

/// A full-width pill filled with the accent (or with the danger colour for
/// an action that loses something), optionally led by an icon. While
/// [isLoading] it shows progress instead of the label and ignores taps.
class NeuPrimaryButton extends StatelessWidget {
  const NeuPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = NeuPrimarySize.large,
    this.danger = false,
  });

  static const _progressSize = 22.0;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppIcons? icon;
  final NeuPrimarySize size;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textStyle = size == NeuPrimarySize.large
        ? context.typography.button
        : context.typography.value.copyWith(color: palette.onAccent);
    return NeuPressable(
      onPressed: isLoading ? () {} : onPressed,
      shadows: context.shadows.raisedAccent(size.depth),
      pressedShadows: context.shadows.insetAccent(size.pressedDepth),
      color: danger ? palette.danger : palette.accent,
      width: double.infinity,
      height: size.height,
      borderRadius: BorderRadius.circular(size.height / 2),
      semanticLabel: label,
      child: isLoading
          ? SizedBox.square(
              dimension: _progressSize,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.onAccent,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (icon != null)
                  AppIcon(icon!, size: 18, color: palette.onAccent),
                Text(label, style: textStyle),
              ],
            ),
    );
  }
}
