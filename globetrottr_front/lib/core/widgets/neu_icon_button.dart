import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

class NeuIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double size;

  const NeuIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onPressed,
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(
          BorderRadius.all(Radius.circular(12.0)),
        ),
        depth: 4,
        intensity: 1,
        shadowLightColor: AppColors.neuLight,
        shadowDarkColor: AppColors.neuShadow,
      ),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
