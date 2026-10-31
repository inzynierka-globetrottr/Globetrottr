import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_writer.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';

class _FailingStorage extends InMemoryFogTileStorage {
  bool failLoads = false;
  bool failCommits = false;

  @override
  Future<List<StoredFogTile>> loadTiles(Iterable<FogTileId> ids) async {
    if (failLoads) throw StateError('load failed');
    return super.loadTiles(ids);
  }

  @override
  Future<void> commit({
    required List<StoredFogTile> upserts,
    required Map<String, double> meta,
  }) async {
    if (failCommits) throw StateError('commit failed');
    return super.commit(upserts: upserts, meta: meta);
  }
}

Future<void> _draw(FogTileCache cache, FogTileId id) async {
  cache.pinned.add(id);
  await cache.ensureLoaded([id]);
  final created = <FogTileId>{};
  cache.maskToDrawInto(id, created).data[0] = 255;
  cache.markDrawn(created, {id});
  cache.pinned.remove(id);
}

FogTileWriter _writer(FogTileCache cache) {
  return FogTileWriter(
    cache,
    baseZoom: FogConfig.baseZoom,
    encodeInIsolate: false,
    isolateEncodeThreshold: FogConfig.isolateEncodeThreshold,
  );
}

Future<void> _write(FogTileWriter writer) {
  return writer.write(revision: 0, totalAreaM2: 0, lastAppliedLogId: 0);
}

void main() {
  final id = tileOf(krakowLat, krakowLng, FogConfig.baseZoom);

  group('FogTileWriter', () {
    test('releases its tiles when loading the pyramid fails', () async {
      final storage = _FailingStorage();
      final cache = FogTileCache(storage, maxTiles: 256);
      await _draw(cache, id);

      storage.failLoads = true;

      await expectLater(_write(_writer(cache)), throwsStateError);
      expect(cache.pinned, isEmpty);
      expect(cache.dirty, {id});
    });

    test('releases its tiles when the commit fails', () async {
      final storage = _FailingStorage();
      final cache = FogTileCache(storage, maxTiles: 256);
      await _draw(cache, id);

      storage.failCommits = true;

      await expectLater(_write(_writer(cache)), throwsStateError);
      expect(cache.pinned, isEmpty);
      expect(cache.dirty, {id});
    });

    test('a write after a failed one stores the tile', () async {
      final storage = _FailingStorage();
      final cache = FogTileCache(storage, maxTiles: 256);
      final writer = _writer(cache);
      await _draw(cache, id);
      storage.failCommits = true;
      await expectLater(_write(writer), throwsStateError);

      storage.failCommits = false;
      await _write(writer);

      expect(cache.dirty, isEmpty);
      expect((await storage.loadTiles([id])).single.id, id);
      expect(await storage.loadTiles([id.ancestorAt(10)]), hasLength(1));
    });

    test('tiles waiting to be written survive eviction', () async {
      final cache = FogTileCache(InMemoryFogTileStorage(), maxTiles: 1);
      final other = FogTileId(id.z, id.x + 1, id.y);
      await _draw(cache, id);
      await _draw(cache, other);

      cache.evict();

      expect(cache.peek(id), isNotNull);
      expect(cache.peek(other), isNotNull);
    });
  });

  group('base tiles', () {
    Future<void> expectQuantized(InMemoryFogTileStorage storage) async {
      final tiles = await decodeAllTiles(storage, FogConfig.baseZoom);
      for (final mask in tiles.values) {
        for (final value in mask.data) {
          if (value == 255) continue;
          expect(value % FogConfig.baseQuantStep, 0);
        }
      }
    }

    test('are on the storage grid when drawn live', () async {
      final storage = InMemoryFogTileStorage();
      final store = await FogStore.open(storage);
      for (final entry in walkEast('a', stepMeters: 7)) {
        await store.applyPoint(
          sessionId: entry.sessionId,
          latitude: entry.latitude,
          longitude: entry.longitude,
        );
      }

      await store.flush();

      await expectQuantized(storage);
      await store.dispose();
    });

    test('are on the storage grid when imported', () async {
      final storage = InMemoryFogTileStorage();
      final store = await FogStore.open(storage);

      await store.importEntries(walkEast('a'), useIsolate: false);
      await store.flush();

      await expectQuantized(storage);
      await store.dispose();
    });
  });
}
