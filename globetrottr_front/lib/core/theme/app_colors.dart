import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  static const background = Color(0xFF1e2530);
  static const neuLight = Color(0xFF2a3443);
  static const neuShadow = Color(0xFF12171e);

  static const text = Color(0xFFe2e8f0);
  static const textLight = Color(0xFF64748b);

  static const active = Color(0xFF4fd1c5);
  static const inactive = Color(0xFF94a3b8);

  static const accentBlue = Color(0xFF38bdf8);
  static const accentGold = Color(0xFFfbbf24);
  static const accentGreen = Color(0xFF48bb78);
  static const accentRed = Color(0xFFf56565);

  /// Undiscovered area; drawn with `FogConfig.fogOpacity`.
  static const fog = Color(0xFF000000);

  // Developer overlays, visible only in dev mode.
  static const devGridReady = Color(0xFF3DDC84);
  static const devGridEmpty = Color(0xFF9AA0A6);
  static const devGridLoading = Color(0xFFFFB300);
  static const devGridUnknown = Color(0xFF4FC3F7);
  static const devGridLabelBackground = Color(0x99000000);
  static const devPixelLines = Color(0x59FFFFFF);
  static const devButton = Color(0xFFFFD600);
  static const devButtonText = Color(0xFF000000);
}
