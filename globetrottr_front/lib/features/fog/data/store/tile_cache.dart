import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';

/// Decodes a stored tile; throws for a damaged one. It runs in background
/// isolates, so it must be a static or top-level function.
typedef TileDecoder<V> = V Function(int flag, Uint8List? bytes);

/// A tile held by a [TileCache].
class TileSlot<V> {
  TileSlot(this.value, {this.areaM2 = 0});

  /// Null means "known to have no data".
  V? value;

  /// Ground area stored with the tile; only layers that track it set it.
  double areaM2;
}

/// The tile of a stored tile, or null for a damaged one. The tiles are a
/// cache of the track log, so a damaged tile counts as missing and a
/// rebuild brings it back.
V? _decodeTile<V>(TileDecoder<V> decode, int flag, Uint8List? bytes) {
  try {
    return decode(flag, bytes);
  } on Object catch (error) {
    debugPrint('Skipping unreadable tile: $error');
    return null;
  }
}

/// Decoded tiles of one layer kept in memory, the least recently used first,
/// whatever a tile holds. Layers add the operations on their own tiles.
///
/// Tiles waiting to be written ([dirty]) and tiles a running operation relies
/// on ([pinned]) are never evicted.
class TileCache<V extends Object> {
  TileCache(
    this.storage, {
    required this.decode,
    required this.maxTiles,
    this.decodeInIsolate = false,
    this.isolateDecodeThreshold = 4,
  });

  final FogTileStorage storage;
  final TileDecoder<V> decode;

  /// Soft limit of cached tiles; dirty and pinned tiles may exceed it.
  final int maxTiles;

  /// Decode large reads in a background isolate to keep the UI smooth.
  final bool decodeInIsolate;
  final int isolateDecodeThreshold;

  final LinkedHashMap<FogTileId, TileSlot<V>> _slots = LinkedHashMap();

  /// Base tiles changed since the last write.
  final Set<FogTileId> dirty = {};

  /// Tiles a running operation relies on; they stay cached until released.
  final Set<FogTileId> pinned = {};

  int _peak = 0;

  /// Grows whenever a tile leaves the cache, so a read that was running at
  /// that moment knows it may hold an older copy of it.
  int _removals = 0;

  int get length => _slots.length;

  /// Most tiles held at once since the cache was created.
  int get peak => _peak;

  TileSlot<V>? operator [](FogTileId id) => _slots[id];

  /// The decoded tile if it is cached, without any I/O.
  V? peek(FogTileId id) => _slots[id]?.value;

  bool isKnownAbsent(FogTileId id) {
    final slot = _slots[id];
    return slot != null && slot.value == null;
  }

  /// Keeps [ids] cached while [action] runs.
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

  /// Marks [id] as the most recently used tile.
  void touch(FogTileId id) {
    final slot = _slots.remove(id);
    if (slot != null) _slots[id] = slot;
  }

  Future<void> ensureLoaded(Iterable<FogTileId> ids) async {
    final missing = ids.where((id) => !_slots.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final stored = await storage.loadTiles(missing);
    _add(stored, await _decode(stored), missing);
  }

  /// Loads the tiles of [range] so [peek] can answer synchronously.
  ///
  /// This runs beside the store's queue, so a tile can be written and evicted,
  /// or cleared, during the read. Such a read is repeated: a stale copy in the
  /// cache would overwrite the newer tile at the next write.
  Future<void> loadRange(FogTileRange range) async {
    final wanted = range.ids.toList();
    if (wanted.every(_slots.containsKey)) {
      wanted.forEach(touch);
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

  Future<List<V?>> _decode(List<StoredFogTile> stored) {
    final tiles = [for (final tile in stored) (tile.flag, tile.bytes)];
    if (!decodeInIsolate || stored.length < isolateDecodeThreshold) {
      return Future.value(_decodeAll(decode, tiles));
    }
    return _decodeInIsolate(decode, tiles);
  }

  // Static, so the closure sent to the isolate cannot capture the cache.
  static Future<List<V?>> _decodeInIsolate<V>(
    TileDecoder<V> decode,
    List<(int, Uint8List?)> tiles,
  ) {
    return Isolate.run(() => _decodeAll(decode, tiles));
  }

  static List<V?> _decodeAll<V>(
    TileDecoder<V> decode,
    List<(int, Uint8List?)> tiles,
  ) {
    return [
      for (final (flag, bytes) in tiles) _decodeTile(decode, flag, bytes),
    ];
  }

  void evict() {
    if (_slots.length <= maxTiles) return;
    for (final id in _slots.keys.toList()) {
      if (_slots.length <= maxTiles) break;
      if (dirty.contains(id) || pinned.contains(id)) continue;
      _slots.remove(id);
      _removals++;
    }
  }

  void clear() {
    _slots.clear();
    dirty.clear();
    pinned.clear();
    _removals++;
  }

  /// Caches the tiles read from [storage] and marks the rest of [requested]
  /// as known to have no data, so they are not read again. A damaged tile
  /// keeps its area, so a redraw replaces it in the total.
  void _add(
    List<StoredFogTile> stored,
    List<V?> tiles,
    Iterable<FogTileId> requested,
  ) {
    for (var i = 0; i < stored.length; i++) {
      final tile = stored[i];
      _slots.putIfAbsent(
        tile.id,
        () => TileSlot(tiles[i], areaM2: tile.areaM2),
      );
    }
    for (final id in requested) {
      _slots.putIfAbsent(id, () => TileSlot<V>(null));
    }
    if (_slots.length > _peak) _peak = _slots.length;
    evict();
  }
}
