import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_writer.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

class FogWriteResult {
  const FogWriteResult({
    required this.revision,
    required this.totalAreaM2,
    required this.tiles,
  });

  final int revision;
  final double totalAreaM2;

  /// Every tile written, on any level of the pyramid.
  final Set<FogTileId> tiles;
}

/// Fog tiles are coverage masks; the coarser levels average them, keeping a
/// minimum strength for thin routes on country-sized views.
class FogTileKind extends TileKind<FogMask> {
  const FogTileKind({required this.baseZoom});

  final int baseZoom;

  @override
  FogMask planeOf(FogMask tile) => tile;

  @override
  FogMask overview() => FogMask();

  @override
  int overviewFloor(int z) =>
      z > FogConfig.overviewFloorMaxZoom ? 0 : FogPyramid.defaultOverviewFloor;

  /// The rasterizer already draws base tiles on the storage grid; only the
  /// averaging of the pyramid creates other values.
  @override
  void finishOverview(FogMask tile) =>
      tile.quantizeInPlace(step: FogConfig.overviewQuantStep);

  @override
  EncodedFogTile encode(FogMask tile) => FogTileCodec.encode(tile);

  @override
  double areaOf(FogTileId id, FogMask tile) {
    final latitude = FogMercator.yToLat(
      (id.y + 0.5) * FogTileId.size,
      baseZoom,
    );
    final pixel = metersPerPixel(
      latitude: latitude,
      zoom: baseZoom.toDouble(),
    );
    return tile.coveredSum / 255.0 * pixel * pixel;
  }
}

/// Writes the modified tiles of a [FogTileCache] to its storage, together
/// with the coarser pyramid levels above them and the store's metadata.
class FogTileWriter {
  FogTileWriter(
    FogTileCache cache, {
    required this.baseZoom,
    required bool encodeInIsolate,
    required int isolateEncodeThreshold,
  }) : _writer = TileWriter(
         cache,
         FogTileKind(baseZoom: baseZoom),
         baseZoom: baseZoom,
         encodeInIsolate: encodeInIsolate,
         isolateEncodeThreshold: isolateEncodeThreshold,
       );

  /// The metadata `FogStore.open` checks to know the tiles were drawn the way
  /// this build draws them. Every metadata write must include it, otherwise
  /// a store holding only a small mark would be taken for an incompatible one
  /// and cleared.
  static Map<String, double> compatibilityMeta({required int baseZoom}) => {
    'baseZoom': baseZoom.toDouble(),
    'minZoom': FogConfig.minZoom.toDouble(),
    'formatVersion': FogTileCodec.formatVersion.toDouble(),
    'drawVersion': FogConfig.drawVersion.toDouble(),
  };

  final int baseZoom;
  final TileWriter<FogMask> _writer;

  /// Writes every tile in [FogTileCache.dirty] and the pyramid above it, and
  /// stores [lastAppliedLogId] with them. A write without modified tiles
  /// only saves the metadata and keeps [revision].
  Future<FogWriteResult> write({
    required int revision,
    required double totalAreaM2,
    required int lastAppliedLogId,
  }) async {
    // The revision counts writes that change tiles; saving only the log
    // position does not make any tile newer.
    final nextRevision = _writer.cache.dirty.isEmpty ? revision : revision + 1;
    var newTotal = totalAreaM2;
    final result = await _writer.write(
      revision: nextRevision,
      meta: (areaDelta) {
        newTotal = (totalAreaM2 + areaDelta).clamp(0.0, double.infinity);
        return {
          'rev': nextRevision.toDouble(),
          'totalAreaM2': newTotal,
          'lastAppliedLogId': lastAppliedLogId.toDouble(),
          ...compatibilityMeta(baseZoom: baseZoom),
        };
      },
    );
    return FogWriteResult(
      revision: nextRevision,
      totalAreaM2: newTotal,
      tiles: result.tiles,
    );
  }
}
