import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = from(AppPalette.light);

  /// A dark mode or another accent is just another palette.
  static ThemeData from(AppPalette palette) {
    final brightness = ThemeData.estimateBrightnessForColor(palette.background);
    final typography = AppTypography.fromPalette(palette);
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        primary: palette.accent,
        onPrimary: palette.onAccent,
        surface: palette.background,
        onSurface: palette.text,
        error: palette.danger,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      // Sheets draw their own surface and shadow; the map stays undimmed.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        modalBarrierColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      iconTheme: IconThemeData(color: palette.text),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.text,
        contentTextStyle: typography.body.copyWith(color: palette.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      extensions: [
        palette,
        typography,
        AppShadows.fromPalette(palette),
      ],
    );
  }
}
