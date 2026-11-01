import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/map/data/track_log/sqflite_track_log_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Future<FogStore> open(InMemoryFogTileStorage tiles) {
    return FogStore.open(tiles, flushDelay: const Duration(hours: 1));
  }

  // Positions with many decimals, so rounding in the log really matters.
  List<TrackLogEntry> journey() => [
    ...walkEast('a', points: 700, stepMeters: 13.37),
    ...walkEast('b', points: 40, startLat: krakowLat + 0.0123456789),
    ...walkEast(
      'a',
      points: 30,
      firstIndex: 5000,
      startLng: krakowLng + 0.0777,
    ),
  ];

  test(
    'the fog drawn live equals the fog rebuilt from the compact log',
    () async {
      final log = SqfliteTrackLogStorage(
        path: inMemoryDatabasePath,
        blockSize: 128,
      );
      addTearDown(log.close);
      final liveTiles = InMemoryFogTileStorage();
      final live = await open(liveTiles);

      // Points arrive one at a time, as while recording; the stored value of
      // each fix is what the fog is drawn from.
      for (final entry in journey()) {
        final stored = await log.append(entry);
        await live.applyPoint(
          sessionId: stored.sessionId,
          latitude: stored.latitude,
          longitude: stored.longitude,
          logId: stored.id,
        );
      }
      await live.flush();
      await log.compact();

      final rebuiltTiles = InMemoryFogTileStorage();
      final rebuilt = await open(rebuiltTiles);
      await rebuilt.rebuildFrom(log, useIsolate: false);

      expect(
        rebuilt.diagnostics.totalAreaM2,
        closeTo(live.diagnostics.totalAreaM2, 1e-6),
      );
      expect(
        sameMasks(
          await decodeAllTiles(liveTiles, FogConfig.baseZoom),
          await decodeAllTiles(rebuiltTiles, FogConfig.baseZoom),
        ),
        isTrue,
      );
      await live.dispose();
      await rebuilt.dispose();
    },
  );

  test(
    'a batch that is imported gives the same fog as the points one by one',
    () async {
      final batchLog = SqfliteTrackLogStorage(
        path: inMemoryDatabasePath,
        blockSize: 128,
      );
      addTearDown(batchLog.close);
      final stored = await batchLog.appendAll(journey());
      final batchTiles = InMemoryFogTileStorage();
      final batch = await open(batchTiles);
      await batch.importEntries(stored, useIsolate: false, chunkSize: 97);
      await batch.flush();

      final liveTiles = InMemoryFogTileStorage();
      final live = await open(liveTiles);
      for (final e in stored) {
        await live.applyPoint(
          sessionId: e.sessionId,
          latitude: e.latitude,
          longitude: e.longitude,
          logId: e.id,
        );
      }
      await live.flush();

      expect(
        sameMasks(
          await decodeAllTiles(batchTiles, FogConfig.baseZoom),
          await decodeAllTiles(liveTiles, FogConfig.baseZoom),
        ),
        isTrue,
      );
      await batch.dispose();
      await live.dispose();
    },
  );

  test(
    'a crash between a point and its flush is repaired by the replay',
    () async {
      final log = SqfliteTrackLogStorage(
        path: inMemoryDatabasePath,
        blockSize: 64,
      );
      addTearDown(log.close);
      final tiles = InMemoryFogTileStorage();
      final store = await open(tiles);
      final entries = journey();
      for (final entry in entries.take(300)) {
        final stored = await log.append(entry);
        await store.applyPoint(
          sessionId: stored.sessionId,
          latitude: stored.latitude,
          longitude: stored.longitude,
          logId: stored.id,
        );
      }
      await store.flush();
      for (final entry in entries.skip(300).take(200)) {
        await log.append(entry);
      }

      final recovered = await open(tiles);
      await recovered.replayFrom(log, useIsolate: false);

      final expectedTiles = InMemoryFogTileStorage();
      final expected = await open(expectedTiles);
      await expected.rebuildFrom(log, useIsolate: false);
      expect(
        sameMasks(
          await decodeAllTiles(tiles, FogConfig.baseZoom),
          await decodeAllTiles(expectedTiles, FogConfig.baseZoom),
        ),
        isTrue,
      );
      expect(recovered.diagnostics.lastAppliedLogId, await log.lastId());
      await store.dispose();
      await recovered.dispose();
      await expected.dispose();
    },
  );
}
