import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
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

List<(int, Uint8List?)> _encodeBatch(List<Uint8List> raw) {
  return [
    for (final data in raw)
      () {
        final encoded = FogTileCodec.encode(FogMask.fromBytes(data));
        return (encoded.flag, encoded.bytes);
      }(),
  ];
}

/// Writes the modified tiles of a [FogTileCache] to its storage, together
/// with the coarser pyramid levels above them and the store's metadata.
class FogTileWriter {
  FogTileWriter(
    this.cache, {
    required this.baseZoom,
    required this.minZoom,
    required this.overviewFloor,
    required this.encodeInIsolate,
    required this.isolateEncodeThreshold,
  });

  final FogTileCache cache;
  final int baseZoom;
  final int minZoom;
  final int overviewFloor;

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
    final changed = <FogTileId>{...baseDirty};
    final ancestors = <FogTileId>{};

    var level = baseDirty;
    for (var z = baseZoom; z > minZoom; z--) {
      final byParent = <FogTileId, List<FogTileId>>{};
      for (final id in level) {
        byParent.putIfAbsent(id.parent!, () => []).add(id);
      }
      cache.pinned.addAll(byParent.keys);
      await cache.ensureLoaded(byParent.keys);
      for (final group in byParent.entries) {
        final entry = cache[group.key]!;
        final parentMask = entry.mask ??= FogMask();
        for (final child in group.value) {
          FogPyramid.downsampleInto(
            child: cache[child]?.mask ?? FogMask(),
            parent: parentMask,
            quadX: child.x & 1,
            quadY: child.y & 1,
            overviewFloor: overviewFloor,
          );
        }
        entry.dirty = true;
      }
      ancestors.addAll(byParent.keys);
      level = byParent.keys.toSet();
    }
    changed.addAll(ancestors);

    var areaDelta = 0.0;
    final upserts = <StoredFogTile>[];
    final newAreas = <FogTileId, double>{};
    final ids = changed.toList();
    final List<EncodedFogTile> encoded;
    try {
      for (final id in ids) {
        cache[id]!.mask!.quantizeInPlace(
          step: id.z == baseZoom
              ? FogConfig.baseQuantStep
              : FogConfig.overviewQuantStep,
        );
      }
      encoded = await _encodeAll([for (final id in ids) cache[id]!.mask!]);
    } on Object {
      cache.pinned.removeAll(ancestors);
      rethrow;
    }
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
    try {
      await cache.storage.commit(
        upserts: upserts,
        meta: {
          'rev': nextRevision.toDouble(),
          'totalAreaM2': newTotal,
          'lastAppliedLogId': lastAppliedLogId.toDouble(),
          'baseZoom': baseZoom.toDouble(),
          'minZoom': minZoom.toDouble(),
          'formatVersion': FogTileCodec.formatVersion.toDouble(),
        },
      );
    } on Object {
      cache.pinned.removeAll(ancestors);
      rethrow;
    }

    for (final id in changed) {
      final entry = cache[id];
      if (entry == null) continue;
      entry.dirty = false;
      final area = newAreas[id];
      if (area != null) entry.areaM2 = area;
    }
    cache.dirty.removeAll(baseDirty);
    cache.pinned.removeAll(ancestors);
    cache.evict();
    return FogWriteResult(
      revision: nextRevision,
      totalAreaM2: newTotal,
      tiles: changed,
    );
  }

  Future<List<EncodedFogTile>> _encodeAll(List<FogMask> masks) async {
    if (!encodeInIsolate || masks.length < isolateEncodeThreshold) {
      return [for (final mask in masks) FogTileCodec.encode(mask)];
    }
    final raw = [for (final mask in masks) mask.data];
    final workers = math.max(
      1,
      math.min(
        math.min(Platform.numberOfProcessors, 4),
        raw.length ~/ isolateEncodeThreshold,
      ),
    );
    final share = (raw.length / workers).ceil();
    final parts = await Future.wait([
      for (var start = 0; start < raw.length; start += share)
        () {
          final slice = raw.sublist(start, math.min(start + share, raw.length));
          return Isolate.run(() => _encodeBatch(slice));
        }(),
    ]);
    return [
      for (final part in parts)
        for (final item in part) EncodedFogTile(item.$1, item.$2),
    ];
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
