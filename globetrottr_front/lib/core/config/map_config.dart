import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 30.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 1;

  static const LatLng initialCenter = LatLng(50.0614, 19.9383); // Kraków

  static const String _baseTileUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static String get tileUrlTemplate {
    final apiKey = dotenv.isInitialized
        ? dotenv.maybeGet('CARTO_API_KEY')
        : null;
    return buildTileUrlTemplate(apiKey: apiKey);
  }

  static String buildTileUrlTemplate({String? apiKey}) {
    final trimmedKey = apiKey?.trim();
    if (trimmedKey != null && trimmedKey.isNotEmpty) {
      return '$_baseTileUrl?key=$trimmedKey';
    }
    return _baseTileUrl;
  }

  static const List<String> tileSubdomains = ['a', 'b', 'c', 'd'];
  static const String tileUserAgentPackageName = 'com.globetrottr.app';
}
