import 'package:flutter/painting.dart';
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

  /// Room left around a quest route fitted on the map, so the controls on
  /// top and the navigation at the bottom do not cover it.
  static const EdgeInsets questRoutePadding = EdgeInsets.fromLTRB(
    40,
    220,
    40,
    150,
  );

  static const LatLng initialCenter = LatLng(50.0614, 19.9383); // Kraków

  static const String tileUserAgentPackageName = 'com.globetrottr.app';

  /// Vector tiles of OpenFreeMap in the OpenMapTiles schema. The TileJSON
  /// names the current tile URL, which changes with every data release.
  static const String basemapTileJsonUrl =
      'https://tiles.openfreemap.org/planet';

  /// How long a tile URL from the TileJSON is used before it is read again,
  /// so a long session does not keep asking for a removed data release.
  static const Duration basemapTileJsonMaxAge = Duration(hours: 12);

  /// Wait before the next TileJSON attempt after a failed refresh, while the
  /// old tile URL is still used.
  static const Duration basemapTileJsonRetryDelay = Duration(minutes: 1);

  /// Longest wait for one base map request, after which it is retried.
  static const Duration basemapRequestTimeout = Duration(seconds: 10);

  static const String basemapSource = 'openmaptiles';

  /// Deepest zoom the server has tiles for; the map scales them up beyond it.
  static const int basemapMaxZoom = 14;
}
