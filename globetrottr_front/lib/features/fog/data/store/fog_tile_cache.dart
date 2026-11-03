import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_cache.dart';

export 'package:globetrottr_front/features/fog/data/store/tile_cache.dart';

FogMask _decodeFogTile(int flag, Uint8List? bytes) =>
    FogTileCodec.decode(flag, bytes);

/// Decoded fog tiles kept in memory, with the fog's own way of drawing into
/// them and merging masks by their maximum.
class FogTileCache extends TileCache<FogMask> {
  FogTileCache(
    super.storage, {
    required super.maxTiles,
    super.decodeInIsolate,
    super.isolateDecodeThreshold,
  }) : super(decode: _decodeFogTile);

  /// The mask a shape is drawn into, created empty for a tile without fog
  /// data (such tiles are added to [created]). It is not marked as modified
  /// here: only the rasterizer knows whether a pixel really changed.
  FogMask maskToDrawInto(FogTileId id, Set<FogTileId> created) {
    touch(id);
    final slot = this[id]!;
    if (slot.value == null) {
      slot.value = FogMask();
      created.add(id);
    }
    return slot.value!;
  }

  /// Records the outcome of drawing: [changed] tiles wait to be written, and
  /// a tile that was only [created] for drawing, without gaining a pixel,
  /// stays absent.
  void markDrawn(Set<FogTileId> created, Set<FogTileId> changed) {
    dirty.addAll(changed);
    for (final id in created.difference(changed)) {
      this[id]!.value = null;
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
        final slot = this[id]!;
        final incoming = FogMask.fromBytes(masks[id.key]!);
        final existing = slot.value;
        final bool changed;
        if (existing == null) {
          changed = !incoming.isEmpty;
          if (changed) slot.value = incoming;
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
}
