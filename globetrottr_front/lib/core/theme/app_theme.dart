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

    // * these text styles are AI generated, but are intended to be used as mocks for now, change after designing more screens

    /// App logo title text
    static const TextStyle appLogo = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
      color: AppColors.text,
    );

    /// Brand subtitle label under logo
    static const TextStyle uppercaseSubtitle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.0,
      color: AppColors.textLight,
    );

    /// Tab buttons text for Login / Register toggle
    static const TextStyle tabButtonText = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textLight,
    );

    /// Input group field descriptors and section dividers
    static const TextStyle inputLabel = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: AppColors.textLight,
    );

    /// Text field input entry and Google login button
    static const TextStyle actionButtonText = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    /// Forgot password hyperlink
    static const TextStyle forgotLinkText = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.accentBlue,
    );

    /// Primary submit call-to-action button
    static const TextStyle submitButtonText = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.accentBlue,
    );

    /// Main metric value displayed on the HUD layer, e.g., "24.8%"
    static const TextStyle screenHeaderLarge = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: AppColors.text,
    );

    /// Upper metric heading labels on the top HUD panel, e.g., "Odkryty Teren"
    static const TextStyle sectionTitle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: AppColors.textLight,
    );

    /// Small informational tracking mode container pill, e.g., "Tryb: Pieszo"
    static const TextStyle viewPillText = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.accentBlue,
    );

    /// Primary text titles for overlay settings selectors, e.g., "Widok: Standardowy"
    static const TextStyle rulesetTitle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    /// Secondary subtext explanations under status controls, e.g., "Wszystkie aktywności..."
    static const TextStyle descriptiveStatusAction = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textLight,
    );
  }