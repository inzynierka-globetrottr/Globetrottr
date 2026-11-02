import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// The main action of a screen: a full-width pill filled with the accent.
class NeuPrimaryButton extends StatelessWidget {
  const NeuPrimaryButton({super.key, required this.label, this.onPressed});

  static const _height = 60.0;

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => NeuPressable(
    onPressed: onPressed,
    shadows: context.shadows.raisedAccent(NeoDepth.xl),
    depth: NeoDepth.md,
    color: context.palette.accent,
    width: double.infinity,
    height: _height,
    borderRadius: BorderRadius.circular(_height / 2),
    child: Text(label, style: context.typography.button),
  );
}
