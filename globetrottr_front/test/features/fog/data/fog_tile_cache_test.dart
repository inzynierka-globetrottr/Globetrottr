import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';

import '../../../support/in_memory_fog_tile_storage.dart';

/// Holds the result of the next [loadRange] after it was read.
class _GatedStorage extends InMemoryFogTileStorage {
  Completer<void>? gate;

  @override
  Future<List<StoredFogTile>> loadRange({
    required int z,
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    final stored = await super.loadRange(
      z: z,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
    );
    final held = gate;
    gate = null;
    await held?.future;
    return stored;
  }
}

const _tile = FogTileId(15, 1, 2);
const _range = FogTileRange(z: 15, xMin: 1, xMax: 1, yMin: 2, yMax: 2);

StoredFogTile _stored(int flag, Uint8List? bytes) {
  return StoredFogTile(id: _tile, flag: flag, rev: 1, areaM2: 5, bytes: bytes);
}

void main() {
  late FogTileCache cache;

  setUp(() {
    cache = FogTileCache(InMemoryFogTileStorage(), maxTiles: 4);
  });

  group('withPinned', () {
    test('pins the tiles while the action runs', () async {
      var pinned = false;

      await cache.withPinned({_tile}, () async {
        pinned = cache.pinned.contains(_tile);
      });

      expect(pinned, isTrue);
      expect(cache.pinned, isEmpty);
    });

    test('hands back the result of the action', () async {
      expect(await cache.withPinned({_tile}, () async => 7), 7);
    });

    test('releases the tiles when the action fails', () async {
      await expectLater(
        cache.withPinned({_tile}, () async => throw StateError('failed')),
        throwsStateError,
      );

      expect(cache.pinned, isEmpty);
    });
  });

  group('loadRange', () {
    test('does not bring back a tile cleared during the read', () async {
      final storage = _GatedStorage();
      await storage.commit(
        upserts: [_stored(FogTileCodec.flagFull, null)],
        meta: const {},
      );
      final gated = FogTileCache(storage, maxTiles: 4);
      final held = Completer<void>();
      storage.gate = held;

      final loading = gated.loadRange(_range);
      await pumpEventQueue();
      await storage.clear();
      gated.clear();
      held.complete();
      await loading;

      expect(gated.peek(_tile), isNull);
      expect(gated.isKnownAbsent(_tile), isTrue);
    });

    test('decodes the same tiles in an isolate', () async {
      final storage = InMemoryFogTileStorage();
      final mask = FogMask()..data[7] = 8;
      final encoded = FogTileCodec.encode(mask);
      await storage.commit(
        upserts: [_stored(encoded.flag, encoded.bytes)],
        meta: const {},
      );
      final background = FogTileCache(
        storage,
        maxTiles: 4,
        decodeInIsolate: true,
        isolateDecodeThreshold: 1,
      );

      await background.loadRange(_range);

      expect(background.peek(_tile)!.data[7], 8);
    });
  });

  group('a damaged tile', () {
    Future<FogTileCache> loaded(Uint8List bytes) async {
      final storage = InMemoryFogTileStorage();
      await storage.commit(
        upserts: [_stored(FogTileCodec.flagData, bytes)],
        meta: const {},
      );
      final damaged = FogTileCache(storage, maxTiles: 4);
      await damaged.loadRange(_range);
      return damaged;
    }

    test('counts as missing when it is not valid zlib', () async {
      final damaged = await loaded(Uint8List.fromList([1, 2, 3]));

      expect(damaged.peek(_tile), isNull);
      expect(damaged.isKnownAbsent(_tile), isTrue);
    });

    test('counts as missing when it has the wrong size', () async {
      final short = Uint8List.fromList(ZLibCodec().encode([1, 2, 3]));

      final damaged = await loaded(short);

      expect(damaged.isKnownAbsent(_tile), isTrue);
    });

    test('keeps its area, so a redraw replaces it in the total', () async {
      final damaged = await loaded(Uint8List.fromList([1, 2, 3]));

      expect(damaged[_tile]!.areaM2, 5);
    });
  });
}
