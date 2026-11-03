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

  /// How long the camera flies to the player after the recenter button.
  static const Duration recenterFlight = Duration(milliseconds: 450);

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

  static const String basemapSource = 'openmaptiles';

  /// Deepest zoom the server has tiles for; the map scales them up beyond it.
  static const int basemapMaxZoom = 14;

  static const String basemapCacheFolder = 'basemap_tiles';

  /// Cached tiles are never revalidated, so this is how stale the map may
  /// get. Expired tiles are deleted even offline, so it must outlast a trip.
  static const Duration basemapCacheTtl = Duration(days: 180);

  /// Raw and rendered tiles together. The package drops files by their last
  /// access time, which Android mostly does not update on reads, so in
  /// practice the oldest written tiles go first.
  static const int basemapCacheMaxBytes = 250 * 1024 * 1024;
}
