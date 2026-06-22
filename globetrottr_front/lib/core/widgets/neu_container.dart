import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

enum NeuElevation { floating, inset, raised }

class NeuContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final NeuElevation elevation;
  final BorderRadius borderRadius;

  const NeuContainer({
    super.key,
    required this.child,
    this.width = 160,
    this.height = 160,
    required this.elevation,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.roundRect(borderRadius),
        depth: elevation == NeuElevation.floating ? 4 : -4,
        intensity: 1,
        shadowLightColor:
            elevation == NeuElevation.floating ? AppColors.neuLight : null,
        shadowDarkColor:
            elevation == NeuElevation.floating ? AppColors.neuShadow : null,
        shadowLightColorEmboss: switch (elevation) {
          NeuElevation.floating => null,
          NeuElevation.inset => AppColors.neuLight,
          NeuElevation.raised => AppColors.neuShadow,
        },
        shadowDarkColorEmboss: switch (elevation) {
          NeuElevation.floating => null,
          NeuElevation.inset => AppColors.neuShadow,
          NeuElevation.raised => AppColors.neuLight,
        },
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}
