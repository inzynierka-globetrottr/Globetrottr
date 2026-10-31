import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 50.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 5;

  /// Longest stretch between two fixes treated as one continuous path; a
  /// longer gap means the device saw nothing in between.
  static const double maxPathGapMeters = 350;

  /// How far the player moves between two redraws, about half a screen pixel
  /// at [defaultZoom]; the limits below keep the rate between 15 and 30 Hz.
  static const double playerStepMeters = 0.3;
  static const Duration playerFastestStep = Duration(milliseconds: 33);
  static const Duration playerSlowestStep = Duration(milliseconds: 66);

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
