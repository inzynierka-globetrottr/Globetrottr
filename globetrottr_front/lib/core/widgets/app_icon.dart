import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// An icon of the design in one colour, or in its own colours when it is not
/// tintable. Without [color] it takes the colour of the surrounding
/// [IconTheme], as a Material icon would (buttons set it).
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 22, this.color});

  final AppIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    icon.asset,
    width: size,
    height: size,
    colorFilter: icon.tintable
        ? ColorFilter.mode(
            color ?? IconTheme.of(context).color ?? context.palette.text,
            BlendMode.srcIn,
          )
        : null,
  );
}
