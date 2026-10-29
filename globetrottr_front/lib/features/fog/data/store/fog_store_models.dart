import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

class FogChange {
  const FogChange(this.tiles, {this.all = false, this.flushed = false});

  /// Tiles whose content changed, on any level of the pyramid.
  final Set<FogTileId> tiles;

  /// True when the whole fog was replaced (cleared or rebuilt).
  final bool all;

  /// True when the change was written to storage, so coarser levels were
  /// refreshed too; false for a live update of the base level only.
  final bool flushed;
}

class FogStoreDiagnostics {
  const FogStoreDiagnostics({
    required this.cachedTiles,
    required this.dirtyTiles,
    required this.revision,
    required this.totalAreaM2,
    required this.appliedPoints,
    required this.lastApplyMicros,
    required this.lastFlushMillis,
    required this.lastFlushTiles,
    required this.peakCachedTiles,
  });

  final int cachedTiles;

  /// Most tiles held in memory at once since the store was opened.
  final int peakCachedTiles;
  final int dirtyTiles;
  final int revision;
  final double totalAreaM2;
  final int appliedPoints;
  final int lastApplyMicros;
  final int lastFlushMillis;
  final int lastFlushTiles;
}
