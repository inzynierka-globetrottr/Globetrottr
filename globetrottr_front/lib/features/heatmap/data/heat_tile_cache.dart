import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile_codec.dart';

/// The tile of a stored heat tile, or null for a damaged one: the tiles are a
/// cache of the track log, so a rebuild brings it back.
HeatTile? _decodeTile(int flag, Uint8List? bytes) {
  try {
    return HeatTileCodec.decode(flag, bytes);
  } on Object catch (error) {
    debugPrint('Skipping unreadable heat tile: $error');
    return null;
  }
}

List<(Uint8List, Uint16List?)?> _decodeBatch(List<(int, Uint8List?)> tiles) {
  return [
    for (final (flag, bytes) in tiles)
      if (_decodeTile(flag, bytes) case final tile?)
        (tile.counts.data, tile.tags)
      else
        null,
  ];
}

/// Decoded heat tiles kept in memory, the least recently used first. Works
/// like the fog's tile cache: [dirty] and [pinned] tiles are never evicted,
/// and a null entry means the tile is known to be empty.
class HeatTileCache {
  HeatTileCache(
    this.storage, {
    required this.maxTiles,
    this.decodeInIsolate = false,
    this.isolateDecodeThreshold = 4,
  });

  final FogTileStorage storage;
  final int maxTiles;
  final bool decodeInIsolate;
  final int isolateDecodeThreshold;

  final LinkedHashMap<FogTileId, HeatTile?> _entries = LinkedHashMap();

  /// Base tiles changed since the last write.
  final Set<FogTileId> dirty = {};

  /// Tiles a running operation relies on; they stay cached until released.
  final Set<FogTileId> pinned = {};

  int _peak = 0;

  /// Grows whenever a tile leaves the cache, so a read running at that
  /// moment knows it may hold an older copy of it.
  int _removals = 0;

  int get length => _entries.length;

  int get peak => _peak;

  HeatTile? operator [](FogTileId id) => _entries[id];

  bool isKnownAbsent(FogTileId id) =>
      _entries.containsKey(id) && _entries[id] == null;

  Future<T> withPinned<T>(
    Iterable<FogTileId> ids,
    Future<T> Function() action,
  ) async {
    pinned.addAll(ids);
    try {
      return await action();
    } finally {
      pinned.removeAll(ids);
    }
  }

  void _touch(FogTileId id) {
    if (!_entries.containsKey(id)) return;
    _entries[id] = _entries.remove(id);
  }

  Future<void> ensureLoaded(Iterable<FogTileId> ids) async {
    final missing = ids.where((id) => !_entries.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final stored = await storage.loadTiles(missing);
    _add(stored, await _decode(stored), missing);
  }

  /// Loads the tiles of [range]. It runs beside the store's queue, so a read
  /// that overlapped an eviction or a clear is repeated.
  Future<void> loadRange(FogTileRange range) async {
    final wanted = range.ids.toList();
    if (wanted.every(_entries.containsKey)) {
      wanted.forEach(_touch);
      return;
    }
    while (true) {
      final removals = _removals;
      final stored = await storage.loadRange(
        z: range.z,
        xMin: range.xMin,
        xMax: range.xMax,
        yMin: range.yMin,
        yMax: range.yMax,
      );
      final tiles = await _decode(stored);
      if (removals != _removals) continue;
      _add(stored, tiles, wanted);
      return;
    }
  }

  Future<List<HeatTile?>> _decode(List<StoredFogTile> stored) async {
    if (!decodeInIsolate || stored.length < isolateDecodeThreshold) {
      return [for (final tile in stored) _decodeTile(tile.flag, tile.bytes)];
    }
    final decoded = await _decodeInIsolate([
      for (final tile in stored) (tile.flag, tile.bytes),
    ]);
    return [
      for (final planes in decoded)
        if (planes == null)
          null
        else
          HeatTile(FogMask.fromBytes(planes.$1), planes.$2),
    ];
  }

  // Static, so the closure sent to the isolate cannot capture the cache.
  static Future<List<(Uint8List, Uint16List?)?>> _decodeInIsolate(
    List<(int, Uint8List?)> tiles,
  ) {
    return Isolate.run(() => _decodeBatch(tiles));
  }

  /// The base tile a session is counted into, created for a tile without
  /// data. It must be loaded.
  HeatTile baseTile(FogTileId id) {
    _touch(id);
    final tile = _entries[id];
    if (tile != null && tile.tags != null) return tile;
    final created = tile == null
        ? HeatTile.base()
        : HeatTile(tile.counts, Uint16List(FogMask.pixels));
    _entries[id] = created;
    return created;
  }

  /// The overview tile a coarser level is drawn into. It must be loaded.
  HeatTile overviewTile(FogTileId id) {
    return _entries[id] ??= HeatTile.overview();
  }

  void evict() {
    if (_entries.length <= maxTiles) return;
    for (final id in _entries.keys.toList()) {
      if (_entries.length <= maxTiles) break;
      if (dirty.contains(id) || pinned.contains(id)) continue;
      _entries.remove(id);
      _removals++;
    }
  }

  void clear() {
    _entries.clear();
    dirty.clear();
    pinned.clear();
    _removals++;
  }

  void _add(
    List<StoredFogTile> stored,
    List<HeatTile?> tiles,
    Iterable<FogTileId> requested,
  ) {
    for (var i = 0; i < stored.length; i++) {
      _entries.putIfAbsent(stored[i].id, () => tiles[i]);
    }
    for (final id in requested) {
      _entries.putIfAbsent(id, () => null);
    }
    if (_entries.length > _peak) _peak = _entries.length;
    evict();
  }
}
