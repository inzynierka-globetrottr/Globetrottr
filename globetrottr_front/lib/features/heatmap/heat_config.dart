/// Tunables of the heatmap. It shares the base level and the pyramid with
/// the fog, counts passes as thin lines and shows them blurred into a
/// density.
abstract final class HeatConfig {
  /// Bumped whenever the way sessions are counted changes, so tiles counted
  /// by an older rule are dropped and rebuilt from the track log.
  static const int algorithmVersion = 1;

  /// Half the width of a pass: a 12 m line. With the fog's 50 m vision
  /// radius every route counted as a band 100 m wide.
  static const double radiusMeters = 6;

  /// The density patches: the kernel in tile pixels (about 10 px on the
  /// screen), the density of a route passed once, where the scale starts,
  /// and the density where it ends.
  static const int densityPixels = 10;
  static const double densityUnit = 0.1;
  static const double densitySaturation = 20;

  /// Exponent of the curve along the scale: only the busiest places turn
  /// yellow and white, so busy and quiet areas are told apart at a glance.
  static const double densityContrast = 3;

  /// A pixel belongs to a pass once the stadium covers it at least this much
  /// (the middle of the soft edge, which lies on the radius).
  static const int countedCoverage = 128;

  /// Sessions after which a place shows the hottest colour. The scale is
  /// logarithmic below it, so the first visits are told apart best.
  static const int saturationSessions = 50;

  /// Soft limit of tiles kept decoded in memory. A base tile holds its
  /// counts and the session that last counted each pixel: 192 KB.
  static const int maxCachedTiles = 96;

  /// Modified tiles are written once this many are waiting.
  static const int maxDirtyTiles = 48;

  /// Base tiles one step of a batch import may touch (about 14 MB).
  static const int importTileBudget = 72;

  /// Modified tiles are written at the latest this long after the first one.
  static const Duration flushDelay = Duration(seconds: 4);
}
