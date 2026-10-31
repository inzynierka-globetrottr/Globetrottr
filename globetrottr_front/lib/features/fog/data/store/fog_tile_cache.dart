import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';

class FogCacheEntry {
  FogCacheEntry(this.mask, {this.areaM2 = 0});

  /// Null means "known to have no fog data".
  FogMask? mask;
  double areaM2;
}

/// The mask of a stored tile, or null for a damaged one. The tiles are a cache
/// of the track log, so a damaged tile counts as missing and a rebuild brings
/// it back.
FogMask? _decodeTile(int flag, Uint8List? bytes) {
  try {
    return FogTileCodec.decode(flag, bytes);
  } on Object catch (error) {
    debugPrint('Skipping unreadable fog tile: $error');
    return null;
  }
}

List<Uint8List?> _decodeBatch(List<(int, Uint8List?)> tiles) {
  return [for (final (flag, bytes) in tiles) _decodeTile(flag, bytes)?.data];
}

/// Decoded fog tiles kept in memory, the least recently used first.
///
/// Tiles waiting to be written ([dirty]) and tiles a running operation relies
/// on ([pinned]) are never evicted.
class FogTileCache {
  FogTileCache(
    this.storage, {
    required this.maxTiles,
    this.decodeInIsolate = false,
    this.isolateDecodeThreshold = 4,
  });

  final FogTileStorage storage;

  /// Soft limit of cached tiles; dirty and pinned tiles may exceed it.
  final int maxTiles;

  /// Decode large reads in a background isolate to keep the UI smooth.
  final bool decodeInIsolate;
  final int isolateDecodeThreshold;

  final LinkedHashMap<FogTileId, FogCacheEntry> _entries = LinkedHashMap();

  /// Base tiles changed since the last write.
  final Set<FogTileId> dirty = {};

  /// Tiles a running operation relies on; they stay cached until released.
  final Set<FogTileId> pinned = {};

  int _peak = 0;

  /// Grows whenever a tile leaves the cache, so a read that was running at
  /// that moment knows it may hold an older copy of it.
  int _removals = 0;

  int get length => _entries.length;

  /// Most tiles held at once since the cache was created.
  int get peak => _peak;

  FogCacheEntry? operator [](FogTileId id) => _entries[id];

  /// The decoded tile if it is cached, without any I/O.
  FogMask? peek(FogTileId id) => _entries[id]?.mask;

  bool isKnownAbsent(FogTileId id) {
    final entry = _entries[id];
    return entry != null && entry.mask == null;
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
    final entry = _entries.remove(id);
    if (entry != null) _entries[id] = entry;
  }

  Future<void> ensureLoaded(Iterable<FogTileId> ids) async {
    final missing = ids.where((id) => !_entries.containsKey(id)).toList();
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
    if (wanted.every(_entries.containsKey)) {
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
      final masks = await _decode(stored);
      if (removals != _removals) continue;
      _add(stored, masks, wanted);
      return;
    }
  }

  Future<List<FogMask?>> _decode(List<StoredFogTile> stored) async {
    if (!decodeInIsolate || stored.length < isolateDecodeThreshold) {
      return [for (final tile in stored) _decodeTile(tile.flag, tile.bytes)];
    }
    final decoded = await _decodeInIsolate([
      for (final tile in stored) (tile.flag, tile.bytes),
    ]);
    return [
      for (final data in decoded)
        if (data == null) null else FogMask.fromBytes(data),
    ];
  }

  // Static, so the closure sent to the isolate cannot capture the cache.
  static Future<List<Uint8List?>> _decodeInIsolate(
    List<(int, Uint8List?)> tiles,
  ) {
    return Isolate.run(() => _decodeBatch(tiles));
  }

  /// The mask a shape is drawn into, created empty for a tile without fog
  /// data (such tiles are added to [created]). It is not marked as modified
  /// here: only the rasterizer knows whether a pixel really changed.
  FogMask maskToDrawInto(FogTileId id, Set<FogTileId> created) {
    touch(id);
    final entry = _entries[id]!;
    if (entry.mask == null) {
      entry.mask = FogMask();
      created.add(id);
    }
    return entry.mask!;
  }

  /// Records the outcome of drawing: [changed] tiles wait to be written, and
  /// a tile that was only [created] for drawing, without gaining a pixel,
  /// stays absent.
  void markDrawn(Set<FogTileId> created, Set<FogTileId> changed) {
    dirty.addAll(changed);
    for (final id in created.difference(changed)) {
      _entries[id]!.mask = null;
    }
  }

  /// Merges masks rasterized elsewhere, keyed by [FogTileId.key], into the
  /// cached tiles with `max`. Returns the tiles that changed.
  Future<Set<FogTileId>> mergeMasks(Map<int, Uint8List> masks) async {
    final ids = [for (final key in masks.keys) FogTileId.fromKey(key)];
    final changedIds = <FogTileId>{};
    await withPinned(ids, () async {
      await ensureLoaded(ids);
      for (final id in ids) {
        touch(id);
        final entry = _entries[id]!;
        final incoming = FogMask.fromBytes(masks[id.key]!);
        final existing = entry.mask;
        final bool changed;
        if (existing == null) {
          changed = !incoming.isEmpty;
          if (changed) entry.mask = incoming;
        } else {
          changed = existing.mergeMax(incoming);
        }
        if (!changed) continue;
        dirty.add(id);
        changedIds.add(id);
      }
    });
    return changedIds;
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

  /// Caches the tiles read from [storage] and marks the rest of [requested]
  /// as known to have no fog data, so they are not read again. A damaged tile
  /// keeps its area, so a redraw replaces it in the total.
  void _add(
    List<StoredFogTile> stored,
    List<FogMask?> masks,
    Iterable<FogTileId> requested,
  ) {
    for (var i = 0; i < stored.length; i++) {
      final tile = stored[i];
      _entries.putIfAbsent(
        tile.id,
        () => FogCacheEntry(masks[i], areaM2: tile.areaM2),
      );
    }
    for (final id in requested) {
      _entries.putIfAbsent(id, () => FogCacheEntry(null));
    }
    if (_entries.length > _peak) _peak = _entries.length;
    evict();
  }
}
