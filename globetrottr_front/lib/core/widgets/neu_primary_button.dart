import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

class NeuPrimaryButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final TextStyle? labelStyle;

  const NeuPrimaryButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.width = double.infinity,
    this.height = 48,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onPressed,
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(
          const BorderRadius.all(Radius.circular(24)),
        ),
        depth: 4,
        intensity: 1,
        shadowLightColor: AppColors.neuLight,
        shadowDarkColor: AppColors.neuShadow,
      ),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: child ?? Text(
            label!,
            style: labelStyle ?? AppTextStyles.submitButtonText,
          ),
        ),
      ),
    );
  }
}