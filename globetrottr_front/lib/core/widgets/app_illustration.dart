import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:globetrottr_front/core/theme/app_illustrations.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// An illustration in its own colours, with the accent of the theme.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.illustration, {super.key, required this.size});

  final AppIllustrations illustration;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    illustration.asset,
    width: size,
    height: size,
    theme: SvgTheme(currentColor: context.palette.accent),
  );
}
