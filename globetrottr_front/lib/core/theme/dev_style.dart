import 'package:flutter/material.dart';

/// Colours of the developer tools. They stand out from the app on purpose and
/// do not follow the theme.
class DevColors {
  DevColors._();

  static const gridReady = Color(0xFF3DDC84);
  static const gridEmpty = Color(0xFF9AA0A6);
  static const gridLoading = Color(0xFFFFB300);
  static const gridUnknown = Color(0xFF4FC3F7);
  static const labelBackground = Color(0x99000000);
  static const pixelLines = Color(0x59FFFFFF);
  static const button = Color(0xFFFFD600);
  static const buttonText = Color(0xFF000000);
}

class DevTextStyles {
  DevTextStyles._();

  /// Names a tile on the fog tile grid of the developer options.
  static const TextStyle gridLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    backgroundColor: DevColors.labelBackground,
  );
}
