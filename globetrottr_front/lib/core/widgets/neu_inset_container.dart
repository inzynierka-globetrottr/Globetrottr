import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

class NeuInsetContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const NeuInsetContainer({
    super.key,
    required this.child,
    this.width = 160,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.roundRect(
          const BorderRadius.all(Radius.circular(24)),
        ),
        depth: -4,
        intensity: 1,
        shadowLightColorEmboss: AppColors.neuLight,
        shadowDarkColorEmboss: AppColors.neuShadow,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}
