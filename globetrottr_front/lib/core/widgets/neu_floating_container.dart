import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

class NeuFloatingContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const NeuFloatingContainer({
    super.key,
    required this.child,
    this.width = 160,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.all(Radius.circular(22))),
        depth: 4,
        intensity: 1,
        shadowLightColor: AppColors.neuLight,
        shadowDarkColor: AppColors.neuShadow,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}