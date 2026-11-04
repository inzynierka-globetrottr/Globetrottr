import 'dart:isolate';
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_cell_areas.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';

/// The cell areas of stored base tiles, decoded in a background isolate.
Future<Map<FogTileId, FogCellAreas>> loadCellAreas(
  FogTileStorage storage,
  List<FogTileId> ids,
) async {
  final stored = await storage.loadTiles(ids);
  final sums = await Isolate.run(() => _cellSums(stored));
  return {
    for (var i = 0; i < stored.length; i++)
      stored[i].id: FogCellAreas.ofSums(stored[i].id, sums[i]),
  };
}

List<Int32List> _cellSums(List<StoredFogTile> tiles) => [
  for (final tile in tiles)
    FogTileCodec.decode(tile.flag, tile.bytes).cellSums(),
];
