import 'dart:collection';
import 'dart:typed_data';

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

/// Decoded fog tiles kept in memory, the least recently used first.
///
/// Tiles waiting to be written ([dirty]) and tiles a running operation relies
/// on ([pinned]) are never evicted.
class FogTileCache {
  FogTileCache(this.storage, {required this.maxTiles});

  final FogTileStorage storage;

  /// Soft limit of cached tiles; dirty and pinned tiles may exceed it.
  final int maxTiles;

  final LinkedHashMap<FogTileId, FogCacheEntry> _entries = LinkedHashMap();

  /// Base tiles changed since the last write.
  final Set<FogTileId> dirty = {};

  /// Tiles a running operation relies on; they stay cached until released.
  final Set<FogTileId> pinned = {};

  int _peak = 0;

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

  /// Marks [id] as the most recently used tile.
  void touch(FogTileId id) {
    final entry = _entries.remove(id);
    if (entry != null) _entries[id] = entry;
  }

  Future<void> ensureLoaded(Iterable<FogTileId> ids) async {
    final missing = ids.where((id) => !_entries.containsKey(id)).toList();
    if (missing.isEmpty) return;
    _add(await storage.loadTiles(missing), missing);
  }

  /// Loads the tiles of [range] so [peek] can answer synchronously.
  Future<void> loadRange(FogTileRange range) async {
    final wanted = range.ids.toList();
    if (wanted.every(_entries.containsKey)) {
      wanted.forEach(touch);
      return;
    }
    final stored = await storage.loadRange(
      z: range.z,
      xMin: range.xMin,
      xMax: range.xMax,
      yMin: range.yMin,
      yMax: range.yMax,
    );
    _add(stored, wanted);
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
    pinned.addAll(ids);
    try {
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
    } finally {
      pinned.removeAll(ids);
    }
    return changedIds;
  }

  void evict() {
    if (_entries.length <= maxTiles) return;
    for (final id in _entries.keys.toList()) {
      if (_entries.length <= maxTiles) break;
      if (dirty.contains(id) || pinned.contains(id)) continue;
      _entries.remove(id);
    }
  }

  void clear() {
    _entries.clear();
    dirty.clear();
    pinned.clear();
  }

  /// Caches the tiles read from [storage] and marks the rest of [requested]
  /// as known to have no fog data, so they are not read again.
  void _add(Iterable<StoredFogTile> stored, Iterable<FogTileId> requested) {
    for (final tile in stored) {
      _entries.putIfAbsent(
        tile.id,
        () => FogCacheEntry(
          FogTileCodec.decode(tile.flag, tile.bytes),
          areaM2: tile.areaM2,
        ),
      );
    }
    for (final id in requested) {
      _entries.putIfAbsent(id, () => FogCacheEntry(null));
    }
    if (_entries.length > _peak) _peak = _entries.length;
    evict();
  }
}
