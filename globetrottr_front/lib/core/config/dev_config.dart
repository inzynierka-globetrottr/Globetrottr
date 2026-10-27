import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class DevConfig {
  static const bool _dartDefineDev =
      bool.fromEnvironment('DEV_MODE') ||
      bool.fromEnvironment('ENABLE_DEV_SCREEN');

  static bool get isDevMode {
    if (kReleaseMode) return false;

    if (_dartDefineDev) return true;

    if (dotenv.isInitialized) {
      final devMode = dotenv.maybeGet('DEV_MODE')?.trim().toLowerCase();
      if (devMode == 'true') return true;

      final enableDev = dotenv
          .maybeGet('ENABLE_DEV_SCREEN')
          ?.trim()
          .toLowerCase();
      if (enableDev == 'true') return true;
    }

    return false;
  }
}
