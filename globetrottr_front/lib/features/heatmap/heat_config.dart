/// Tunables of the heatmap. It shares the base level, the pyramid and the
/// vision radius with the fog, so a place in the heatmap is exactly a place
/// the fog reveals.
abstract final class HeatConfig {
  /// Bumped whenever the way sessions are counted changes, so tiles counted
  /// by an older rule are dropped and rebuilt from the track log.
  static const int algorithmVersion = 1;

  /// A pixel belongs to a pass once the stadium covers it at least this much
  /// (the middle of the soft edge, which lies on the vision radius).
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
