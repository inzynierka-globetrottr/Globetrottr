import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 30.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 1;

  static const double questMarkerSize = 40.0;
  static const double questMarkerIconSize = 22.0;
  static const double questMarkerBorderWidth = 3.0;
  static const double questMarkerSelectedBorderWidth = 5.0;
  static const double questRouteStrokeWidth = 5.0;
  static const double questPointRadius = 10.0;
  static const double questPointBorderWidth = 2.0;
  static const double questPointFillAlpha = 0.35;
  static const double questMarkerShadowAlpha = 0.4;
  static const double questMarkerShadowBlur = 8.0;
  static const double questMarkerShadowSpread = 2.0;

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
