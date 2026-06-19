import 'package:latlong2/latlong.dart';

class MapConfig {
  static const double defaultVisionRadius = 30.0;
  static const double defaultZoom = 16.0;
  static const int distanceFilter = 1;

  static const LatLng initialCenter = LatLng(50.0614, 19.9383); // Kraków

  // TODO: think about changing styling
  static const String tileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  static const List<String> tileSubdomains = ['a', 'b', 'c', 'd'];
  static const String tileUserAgentPackageName = 'com.globetrottr.app';
}
