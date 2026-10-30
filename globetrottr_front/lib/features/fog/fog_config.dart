import 'package:globetrottr_front/core/config/map_config.dart';

/// Tunables of the bitmap fog. Zoom 16 is about 1.47 m per pixel at 52 N,
/// so the 30 m vision radius is a disc of roughly 20 px. Zoom 17 would be
/// twice as sharp and take twice the space; at the usual walking zoom the
/// difference on screen is small.
abstract final class FogConfig {
  /// Most detailed level; everything is rasterized here.
  static const int baseZoom = 16;

  /// Coarsest level of the display pyramid.
  static const int minZoom = 4;

  static const double visionRadiusMeters = MapConfig.defaultVisionRadius;

  /// Longest stretch joined into one path. About 1200 km/h at one fix per
  /// second; a longer gap between two fixes starts a new path.
  static const double maxSegmentMeters = 350;

  /// Bumped whenever the way points are drawn changes, so tiles drawn by an
  /// older rule are dropped and rebuilt from the track log.
  static const int drawVersion = 1;

  /// Width of the anti-aliased rim of every stored shape, in base pixels.
  static const double edgeWidthPixels = 1.5;

  /// Soft limit of tiles (64 KB each) kept decoded in memory: 16 MB.
  static const int maxCachedTiles = 256;

  /// Modified tiles are written once this many are waiting.
  static const int maxDirtyTiles = 96;

  /// Base tiles one step of a batch import may touch (about 16 MB of masks).
  static const int importTileBudget = 256;

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
