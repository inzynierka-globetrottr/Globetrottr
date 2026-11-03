import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/app_typography.dart';

/// Design tokens of the current theme. Outside the app theme (some tests)
/// the light tokens are used.
extension ThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  AppTypography get typography =>
      Theme.of(this).extension<AppTypography>() ??
      AppTypography.fromPalette(palette);

  AppShadows get shadows =>
      Theme.of(this).extension<AppShadows>() ?? AppShadows.fromPalette(palette);

  /// Instant when the system asks for no animations.
  AppMotion get motion {
    final motion = Theme.of(this).extension<AppMotion>() ?? AppMotion.standard;
    final disabled = MediaQuery.maybeDisableAnimationsOf(this) ?? false;
    return disabled ? motion.reduced : motion;
  }
}
