import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accentBlue,
      error: AppColors.accentRed,
    ),
    fontFamily: 'SF Pro Display',
    useMaterial3: true,
  );
}
class AppTextStyles {
  AppTextStyles._();

  // logo
  static const appLogo = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.text,
  );

  // standard bold / inputs
  static const bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // large metrics
  static const metricValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.text,
  );

  // labels
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: AppColors.textLight,
  );

  // secondary links
  static const tabLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  // small captions / descriptions
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  // main action buttons
  static const buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.accentBlue,
  );
}