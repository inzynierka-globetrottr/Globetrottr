import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_cache.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_writer.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile_codec.dart';

HeatTile _decodeHeatTile(int flag, Uint8List? bytes) =>
    HeatTileCodec.decode(flag, bytes);

/// Heatmap tiles build their coarser levels from the session counts and keep
/// the busiest of four pixels, so a route stays visible on a country-sized
/// view.
class HeatTileKind extends TileKind<HeatTile> {
  const HeatTileKind();

  @override
  FogMask planeOf(HeatTile tile) => tile.counts;

  @override
  HeatTile overview() => HeatTile.overview();

  @override
  int overviewFloor(int z) => 255;

  @override
  EncodedFogTile encode(HeatTile tile) => HeatTileCodec.encode(tile);
}

/// Decoded heatmap tiles kept in memory: base tiles with the session that
/// last counted each pixel, coarser tiles with counts only.
class HeatTileCache extends TileCache<HeatTile> {
  HeatTileCache(
    super.storage, {
    required super.maxTiles,
    super.decodeInIsolate,
    super.isolateDecodeThreshold,
  }) : super(decode: _decodeHeatTile);

  /// The base tile a session is counted into, created for a tile without
  /// data. It must be loaded.
  HeatTile baseTile(FogTileId id) {
    touch(id);
    final slot = this[id]!;
    final tile = slot.value;
    if (tile != null && tile.tags != null) return tile;
    // A stored tile without tags has no counts either (see HeatTileCodec).
    return slot.value = tile == null
        ? HeatTile.base()
        : HeatTile(tile.counts, Uint16List(FogMask.pixels));
  }
}
