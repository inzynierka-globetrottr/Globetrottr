import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:globetrottr_front/core/config/map_config.dart';

/// Tunables of the bitmap fog. Zoom 15 is about 2.9 m per pixel at 52 N,
/// so the 50 m vision radius is a disc of roughly 17 px. Zoom 16 would be
/// twice as sharp and take twice the space; at the usual walking zoom the
/// difference on screen is small.
abstract final class FogConfig {
  /// Most detailed level; everything is rasterized here.
  static const int baseZoom = 15;

  /// Coarsest level of the display pyramid.
  static const int minZoom = 4;

  static const double visionRadiusMeters = MapConfig.defaultVisionRadius;

  /// Longest stretch joined into one path. About 1200 km/h at one fix per
  /// second; a longer gap between two fixes starts a new path.
  static const double maxSegmentMeters = 350;

  /// Most base tiles one path may cover (about 4 MB of masks). A safety net
  /// next to [maxSegmentMeters]; it only matters at extreme latitudes.
  static const int maxTilesPerSegment = 64;

  /// Bumped whenever the way points are drawn changes, so tiles drawn by an
  /// older rule are dropped and rebuilt from the track log.
  static const int drawVersion = 4;

  /// Width of the anti-aliased rim of every stored shape, in base pixels.
  static const double edgeWidthPixels = 1.5;

  /// Soft limit of tiles (64 KB each) kept decoded in memory: 16 MB.
  static const int maxCachedTiles = 256;

  /// Modified tiles are written once this many are waiting.
  static const int maxDirtyTiles = 96;

  /// Base tiles one step of a batch import may touch (about 16 MB of masks).
  static const int importTileBudget = 256;

  /// A replay step that was started this many times without finishing (the
  /// app died or failed in it) is skipped, so a poisonous stretch of the log
  /// cannot block every start.
  static const int maxReplayStepAttempts = 2;

  /// Size of the replay step that follows an unfinished one: if the step
  /// fails again only this many entries are skipped.
  static const int retryStepEntries = 50;

  /// Modified tiles are written at the latest this long after the first one.
  static const Duration flushDelay = Duration(seconds: 4);

  /// Stored coverage of base tiles is rounded to multiples of this.
  static const int baseQuantStep = 16;

  /// Overview tiles are only for display, so eight levels are plenty.
  static const int overviewQuantStep = 32;

  /// A write of at least this many tiles is compressed in an isolate.
  static const int isolateEncodeThreshold = 24;

  /// Most isolates one batch of work may use at the same time.
  static int get isolateWorkers => math.min(Platform.numberOfProcessors, 4);

  static const double fogOpacity = 0.75;
}
