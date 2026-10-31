import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

class StoredFogTile {
  const StoredFogTile({
    required this.id,
    required this.flag,
    required this.rev,
    required this.areaM2,
    this.bytes,
  });

  final FogTileId id;

  /// See `FogTileCodec`: 0 empty, 1 full, 2 zlib payload.
  final int flag;

  /// Revision of the commit that last wrote this tile.
  final int rev;

  /// Ground area revealed in this tile, only tracked on the base level.
  final double areaM2;
  final Uint8List? bytes;
}

class FogStorageStats {
  const FogStorageStats({
    required this.tileCount,
    required this.totalBytes,
    required this.tilesPerLevel,
  });

  final int tileCount;
  final int totalBytes;
  final Map<int, int> tilesPerLevel;
}

abstract class FogTileStorage {
  Future<List<StoredFogTile>> loadTiles(Iterable<FogTileId> ids);

  Future<List<StoredFogTile>> loadRange({
    required int z,
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  });

  /// Tiles written by a commit newer than [rev], for differential sync.
  Future<List<StoredFogTile>> changedSince(int rev, {int limit = 1000});

  /// Writes [upserts] and [meta] atomically.
  Future<void> commit({
    required List<StoredFogTile> upserts,
    required Map<String, double> meta,
  });

  Future<Map<String, double>> loadMeta();

  Future<FogStorageStats> stats();

  /// Size on disk of the database file and its journal files.
  Future<int> fileBytes();

  Future<void> clear();

  Future<void> close();
}
