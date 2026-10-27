import 'package:globetrottr_front/core/config/map_config.dart';

/// Tunables of the bitmap fog. Zoom 17 is about 0.74 m per pixel at 52 N,
/// so the 30 m vision radius is a disc of roughly 41 px.
abstract final class FogConfig {
  /// Most detailed level; everything is rasterized here.
  static const int baseZoom = 17;

  /// Coarsest level of the display pyramid.
  static const int minZoom = 4;

  static const double visionRadiusMeters = MapConfig.defaultVisionRadius;

  /// Width of the anti-aliased rim of every stored shape, in base pixels.
  static const double edgeWidthPixels = 1.5;

  /// Soft limit of tiles (64 KB each) kept decoded in memory: 16 MB.
  static const int maxCachedTiles = 256;

  /// Modified tiles are written once this many are waiting.
  static const int maxDirtyTiles = 96;

  /// Modified tiles are written at the latest this long after the first one.
  static const Duration flushDelay = Duration(seconds: 4);

  /// Stored coverage of base tiles is rounded to multiples of this.
  static const int baseQuantStep = 16;

  /// Overview tiles are only for display, so eight levels are plenty.
  static const int overviewQuantStep = 32;

  /// A write of at least this many tiles is compressed in an isolate.
  static const int isolateEncodeThreshold = 24;

  static const double fogOpacity = 0.75;
}
