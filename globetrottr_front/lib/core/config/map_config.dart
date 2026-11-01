import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 50.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 5;

  /// Longest stretch between two fixes treated as one continuous path, about
  /// 1200 km/h at one fix per second; a longer gap means the device saw
  /// nothing in between.
  static const double maxPathGapMeters = 350;

  /// How far the player moves between two redraws, about half a screen pixel
  /// at [defaultZoom]; the limits below keep the rate between 15 and 30 Hz.
  static const double playerStepMeters = 0.3;
  static const Duration playerFastestStep = Duration(milliseconds: 33);
  static const Duration playerSlowestStep = Duration(milliseconds: 66);

  static const LatLng initialCenter = LatLng(50.0614, 19.9383); // Kraków

  static const String tileUserAgentPackageName = 'com.globetrottr.app';

  static String get tileUrlTemplate {
    final cartoKey = dotenv.isInitialized ? dotenv.env['CARTO_API_KEY'] : null;
    if (cartoKey != null && cartoKey.isNotEmpty) {
      return 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=$cartoKey';
    }
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  static List<String> get tileSubdomains {
    final cartoKey = dotenv.isInitialized ? dotenv.env['CARTO_API_KEY'] : null;
    if (cartoKey != null && cartoKey.isNotEmpty) {
      return const ['a', 'b', 'c', 'd'];
    }
    return const [];
  }
}
