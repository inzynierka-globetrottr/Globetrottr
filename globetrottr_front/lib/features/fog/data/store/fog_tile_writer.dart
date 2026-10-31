import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

class FogWriteResult {
  const FogWriteResult({
    required this.revision,
    required this.totalAreaM2,
    required this.tiles,
  });

  final int revision;
  final double totalAreaM2;

  /// Every tile written, on any level of the pyramid.
  final Set<FogTileId> tiles;
}

List<EncodedFogTile> _encodeBatch(List<Uint8List> raw) {
  return [for (final data in raw) FogTileCodec.encode(FogMask.fromBytes(data))];
}

/// Writes the modified tiles of a [FogTileCache] to its storage, together
/// with the coarser pyramid levels above them and the store's metadata.
class FogTileWriter {
  FogTileWriter(
    this.cache, {
    required this.baseZoom,
    required this.encodeInIsolate,
    required this.isolateEncodeThreshold,
  });

  /// The metadata `FogStore.open` checks to know the tiles were drawn the way
  /// this build draws them. Every metadata write must include it, otherwise
  /// a store holding only a small mark would be taken for an incompatible one
  /// and cleared.
  static Map<String, double> compatibilityMeta({required int baseZoom}) => {
    'baseZoom': baseZoom.toDouble(),
    'minZoom': FogConfig.minZoom.toDouble(),
    'formatVersion': FogTileCodec.formatVersion.toDouble(),
    'drawVersion': FogConfig.drawVersion.toDouble(),
  };

  final FogTileCache cache;
  final int baseZoom;

  /// Compress large writes in a background isolate to keep the UI smooth.
  final bool encodeInIsolate;
  final int isolateEncodeThreshold;

  /// Writes every tile in [FogTileCache.dirty] and the pyramid above it, and
  /// stores [lastAppliedLogId] with them. A write without modified tiles
  /// only saves the metadata and keeps [revision].
  Future<FogWriteResult> write({
    required int revision,
    required double totalAreaM2,
    required int lastAppliedLogId,
  }) async {
    final baseDirty = cache.dirty.toSet();
    // The revision counts writes that change tiles; saving only the log
    // position does not make any tile newer.
    final nextRevision = baseDirty.isEmpty ? revision : revision + 1;
    final ancestors = <FogTileId>{};

    try {
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
          final parentMask = cache[group.key]!.mask ??= FogMask();
          for (final child in group.value) {
            FogPyramid.downsampleInto(
              child: cache[child]?.mask ?? FogMask(),
              parent: parentMask,
              quadX: child.x & 1,
              quadY: child.y & 1,
            );
          }
        }
        level = byParent.keys.toSet();
      }

      // The rasterizer already draws base tiles on the storage grid; only
      // the averaging of the pyramid creates other values.
      for (final id in ancestors) {
        cache[id]!.mask!.quantizeInPlace(step: FogConfig.overviewQuantStep);
      }

      final changed = <FogTileId>{...baseDirty, ...ancestors};
      final ids = changed.toList();
      final encoded = await _encodeAll([
        for (final id in ids) cache[id]!.mask!,
      ]);

      var areaDelta = 0.0;
      final upserts = <StoredFogTile>[];
      final newAreas = <FogTileId, double>{};
      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];
        final entry = cache[id]!;
        var area = 0.0;
        if (id.z == baseZoom) {
          area = _areaOf(id, entry.mask!);
          areaDelta += area - entry.areaM2;
          newAreas[id] = area;
        }
        upserts.add(
          StoredFogTile(
            id: id,
            flag: encoded[i].flag,
            rev: nextRevision,
            areaM2: area,
            bytes: encoded[i].bytes,
          ),
        );
      }

      final newTotal = math.max(0.0, totalAreaM2 + areaDelta);
      await cache.storage.commit(
        upserts: upserts,
        meta: {
          'rev': nextRevision.toDouble(),
          'totalAreaM2': newTotal,
          'lastAppliedLogId': lastAppliedLogId.toDouble(),
          ...compatibilityMeta(baseZoom: baseZoom),
        },
      );

      newAreas.forEach((id, area) => cache[id]!.areaM2 = area);
      cache.dirty.removeAll(baseDirty);
      return FogWriteResult(
        revision: nextRevision,
        totalAreaM2: newTotal,
        tiles: changed,
      );
    } finally {
      cache.pinned.removeAll(ancestors);
      cache.evict();
    }
  }

  Future<List<EncodedFogTile>> _encodeAll(List<FogMask> masks) async {
    if (!encodeInIsolate || masks.length < isolateEncodeThreshold) {
      return [for (final mask in masks) FogTileCodec.encode(mask)];
    }
    final raw = [for (final mask in masks) mask.data];
    final workers = math.max(
      1,
      math.min(FogConfig.isolateWorkers, raw.length ~/ isolateEncodeThreshold),
    );
    final share = (raw.length / workers).ceil();
    final parts = await Future.wait([
      for (var start = 0; start < raw.length; start += share)
        () {
          final slice = raw.sublist(start, math.min(start + share, raw.length));
          return Isolate.run(() => _encodeBatch(slice));
        }(),
    ]);
    return [for (final part in parts) ...part];
  }

  double _areaOf(FogTileId id, FogMask mask) {
    final latitude = FogMercator.yToLat(
      (id.y + 0.5) * FogTileId.size,
      baseZoom,
    );
    final pixel = metersPerPixel(
      latitude: latitude,
      zoom: baseZoom.toDouble(),
    );
    return mask.coveredSum / 255.0 * pixel * pixel;
  }
}
