import 'package:flutter_dotenv/flutter_dotenv.dart';

class DevConfig {
  static const bool _dartDefineDev =
      bool.fromEnvironment('DEV_MODE') ||
      bool.fromEnvironment('ENABLE_DEV_SCREEN');

  static bool get isDevMode {
    if (_dartDefineDev) return true;

    if (dotenv.isInitialized) {
      final devMode = dotenv.maybeGet('DEV_MODE')?.trim().toLowerCase();
      if (devMode == 'true' || devMode == '1') return true;

      final enableDev = dotenv
          .maybeGet('ENABLE_DEV_SCREEN')
          ?.trim()
          .toLowerCase();
      if (enableDev == 'true' || enableDev == '1') return true;
    }

    return false;
  }
}
