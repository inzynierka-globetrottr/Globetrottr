import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 30.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 1;

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
