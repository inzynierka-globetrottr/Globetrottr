import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';

class InMemoryFogTileStorage implements FogTileStorage {
  final Map<int, StoredFogTile> _tiles = {};
  final Map<String, double> _meta = {};

  @override
  Future<List<StoredFogTile>> loadTiles(Iterable<FogTileId> ids) async {
    return [
      for (final id in ids)
        if (_tiles[id.key] case final tile?) tile,
    ];
  }

  @override
  Future<List<StoredFogTile>> loadRange({
    required int z,
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    final result = <StoredFogTile>[];
    final cells = (xMax - xMin + 1) * (yMax - yMin + 1);
    if (cells <= _tiles.length) {
      for (var x = xMin; x <= xMax; x++) {
        for (var y = yMin; y <= yMax; y++) {
          final tile = _tiles[FogTileId(z, x, y).key];
          if (tile != null) result.add(tile);
        }
      }
    } else {
      for (final tile in _tiles.values) {
        final id = tile.id;
        if (id.z == z &&
            id.x >= xMin &&
            id.x <= xMax &&
            id.y >= yMin &&
            id.y <= yMax) {
          result.add(tile);
        }
      }
    }
    return result;
  }

  @override
  Future<List<StoredFogTile>> changedSince(int rev, {int limit = 1000}) async {
    return _tiles.values.where((t) => t.rev > rev).take(limit).toList();
  }

  @override
  Future<void> commit({
    required List<StoredFogTile> upserts,
    required Map<String, double> meta,
  }) async {
    for (final tile in upserts) {
      _tiles[tile.id.key] = tile;
    }
    _meta.addAll(meta);
  }

  @override
  Future<Map<String, double>> loadMeta() async => Map.of(_meta);

  @override
  Future<FogStorageStats> stats() async {
    final perLevel = <int, int>{};
    var bytes = 0;
    for (final tile in _tiles.values) {
      perLevel.update(tile.id.z, (n) => n + 1, ifAbsent: () => 1);
      bytes += tile.bytes?.length ?? 0;
    }
    return FogStorageStats(
      tileCount: _tiles.length,
      totalBytes: bytes,
      tilesPerLevel: perLevel,
    );
  }

  @override
  Future<int> fileBytes() async => 0;

  @override
  Future<void> clear() async {
    _tiles.clear();
    _meta.clear();
  }

  @override
  Future<void> close() async {}
}
