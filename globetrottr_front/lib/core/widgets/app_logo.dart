import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// The globe of the logo on a disc in the accent colour.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  static const _box = 104.0;
  static const _disc = 88.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _box,
    child: Center(
      child: NeuSurface.circle(
        shadows: context.shadows.logo,
        color: context.palette.accent,
        size: _disc,
        child: const AppIcon(AppIcons.globe, size: _disc),
      ),
    ),
  );
}
