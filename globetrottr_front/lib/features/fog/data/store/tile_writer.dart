import 'dart:isolate';
import 'dart:math' as math;

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/tile_cache.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

/// What the tiles of one layer are made of, so [TileWriter] can build their
/// pyramid and store them. It goes to background isolates, so it holds no
/// state.
abstract class TileKind<V extends Object> {
  const TileKind();

  /// The 8-bit plane the coarser levels are built from.
  FogMask planeOf(V tile);

  /// An empty tile of a coarser level.
  V overview();

  /// The `overviewFloor` of [FogPyramid.downsampleInto] for level [z].
  int overviewFloor(int z);

  /// Called on every coarser tile once it is drawn.
  void finishOverview(V tile) {}

  EncodedFogTile encode(V tile);

  /// Ground area of a base tile, or 0 when the layer does not track it.
  double areaOf(FogTileId id, V tile) => 0;
}

class TileWriteResult {
  const TileWriteResult({required this.tiles, required this.areaDelta});

  /// Every tile written, on any level of the pyramid.
  final Set<FogTileId> tiles;

  /// Change of the ground area of the base tiles.
  final double areaDelta;
}

List<EncodedFogTile> _encodeBatch<V extends Object>(
  TileKind<V> kind,
  List<V> tiles,
) {
  return [for (final tile in tiles) kind.encode(tile)];
}

/// Writes the modified tiles of a [TileCache] to its storage, together with
/// the coarser pyramid levels above them and the layer's metadata.
class TileWriter<V extends Object> {
  TileWriter(
    this.cache,
    this.kind, {
    required this.baseZoom,
    required this.encodeInIsolate,
    required this.isolateEncodeThreshold,
  });

  final TileCache<V> cache;
  final TileKind<V> kind;
  final int baseZoom;

  /// Compress large writes in a background isolate to keep the UI smooth.
  final bool encodeInIsolate;
  final int isolateEncodeThreshold;

  /// Writes every tile in [TileCache.dirty] and the pyramid above it with
  /// [revision], and the metadata [meta] gives for the area change, all in
  /// one commit.
  Future<TileWriteResult> write({
    required int revision,
    required Map<String, double> Function(double areaDelta) meta,
  }) async {
    final baseDirty = cache.dirty.toSet();
    final ancestors = <FogTileId>{};

    try {
      await _refreshPyramid(baseDirty, ancestors);
      for (final id in ancestors) {
        kind.finishOverview(cache[id]!.value!);
      }

      final ids = [...baseDirty, ...ancestors];
      final encoded = await _encodeAll([
        for (final id in ids) cache[id]!.value!,
      ]);

      var areaDelta = 0.0;
      final upserts = <StoredFogTile>[];
      final newAreas = <FogTileId, double>{};
      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];
        final slot = cache[id]!;
        var area = 0.0;
        if (id.z == baseZoom) {
          area = kind.areaOf(id, slot.value!);
          areaDelta += area - slot.areaM2;
          newAreas[id] = area;
        }
        upserts.add(
          StoredFogTile(
            id: id,
            flag: encoded[i].flag,
            rev: revision,
            areaM2: area,
            bytes: encoded[i].bytes,
          ),
        );
      }

      await cache.storage.commit(upserts: upserts, meta: meta(areaDelta));

      newAreas.forEach((id, area) => cache[id]!.areaM2 = area);
      cache.dirty.removeAll(baseDirty);
      return TileWriteResult(tiles: ids.toSet(), areaDelta: areaDelta);
    } finally {
      cache.pinned.removeAll(ancestors);
      cache.evict();
    }
  }

  Future<void> _refreshPyramid(
    Set<FogTileId> baseDirty,
    Set<FogTileId> ancestors,
  ) async {
    var level = baseDirty;
    for (var z = baseZoom; z > FogConfig.minZoom; z--) {
      final byParent = <FogTileId, List<FogTileId>>{};
      for (final id in level) {
        byParent.putIfAbsent(id.ancestorAt(z - 1), () => []).add(id);
      }
      ancestors.addAll(byParent.keys);
      cache.pinned.addAll(byParent.keys);
      await cache.ensureLoaded(byParent.keys);
      for (final group in byParent.entries) {
        final slot = cache[group.key]!;
        final parent = kind.planeOf(slot.value ??= kind.overview());
        for (final child in group.value) {
          final tile = cache[child]?.value;
          FogPyramid.downsampleInto(
            child: tile == null ? FogMask() : kind.planeOf(tile),
            parent: parent,
            quadX: child.x & 1,
            quadY: child.y & 1,
            overviewFloor: kind.overviewFloor(z - 1),
          );
        }
      }
      level = byParent.keys.toSet();
    }
  }

  Future<List<EncodedFogTile>> _encodeAll(List<V> tiles) async {
    // A local, so the closure sent to the isolate does not capture the writer.
    final kind = this.kind;
    if (!encodeInIsolate || tiles.length < isolateEncodeThreshold) {
      return _encodeBatch(kind, tiles);
    }
    final workers = math.max(
      1,
      math.min(
        FogConfig.isolateWorkers,
        tiles.length ~/ isolateEncodeThreshold,
      ),
    );
    final share = (tiles.length / workers).ceil();
    final parts = await Future.wait([
      for (var start = 0; start < tiles.length; start += share)
        () {
          final end = math.min(start + share, tiles.length);
          final slice = tiles.sublist(start, end);
          return Isolate.run(() => _encodeBatch(kind, slice));
        }(),
    ]);
    return [for (final part in parts) ...part];
  }
}
