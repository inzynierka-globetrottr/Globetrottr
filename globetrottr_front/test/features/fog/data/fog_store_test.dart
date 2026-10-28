import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_query.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_test_helpers.dart';

Future<FogStore> _open(
  FogTileStorage storage, {
  int maxCachedTiles = 256,
  int maxDirtyTiles = 96,
  int baseZoom = FogConfig.baseZoom,
}) {
  return FogStore.open(
    storage,
    baseZoom: baseZoom,
    maxCachedTiles: maxCachedTiles,
    maxDirtyTiles: maxDirtyTiles,
    flushDelay: const Duration(hours: 1),
  );
}

int _rowOf(double lat) =>
    (FogMercator.latToY(lat, FogConfig.baseZoom) % FogTileId.size).floor();

Future<void> _apply(FogStore store, String session, double lat, double lng) {
  return store.applyPoint(sessionId: session, latitude: lat, longitude: lng);
}

enum _LogCall { count, entriesAfter }

/// A track log that can hold a replay at its next [count] or [entriesAfter]
/// call, so a test can log a new position in the middle of the replay.
class _PausingTrackLog extends InMemoryTrackLogStorage {
  final Completer<void> paused = Completer<void>();
  final Completer<void> _resume = Completer<void>();
  _LogCall? pauseAt;

  void resume() => _resume.complete();

  Future<void> _maybePause(_LogCall call) async {
    if (pauseAt != call) return;
    pauseAt = null;
    paused.complete();
    await _resume.future;
  }

  @override
  Future<int> count() async {
    await _maybePause(_LogCall.count);
    return super.count();
  }

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    await _maybePause(_LogCall.entriesAfter);
    return super.entriesAfter(afterId, limit: limit);
  }
}

/// A track log whose first [entriesAfter] call fails, like a damaged block.
class _FailingOnceTrackLog extends InMemoryTrackLogStorage {
  bool _failed = false;

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    if (!_failed) {
      _failed = true;
      throw StateError('damaged track block');
    }
    return super.entriesAfter(afterId, limit: limit);
  }
}

Future<void> _applyLogged(FogStore store, TrackLogEntry entry) {
  return store.applyPoint(
    sessionId: entry.sessionId,
    latitude: entry.latitude,
    longitude: entry.longitude,
    logId: entry.id,
  );
}

void main() {
  late InMemoryFogTileStorage storage;
  late FogStore store;

  setUp(() async {
    storage = InMemoryFogTileStorage();
    store = await _open(storage);
  });

  tearDown(() => store.dispose());

  group('applying points', () {
    test('a point reveals a disc of the vision radius', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      final query = FogQuery(store);

      final inside = offsetMeters(krakowLat, krakowLng, north: 25);
      final outside = offsetMeters(krakowLat, krakowLng, north: 36);

      expect(await query.coverageAt(krakowLat, krakowLng), 1);
      expect(await query.coverageAt(inside.lat, inside.lng), greaterThan(0.99));
      expect(await query.coverageAt(outside.lat, outside.lng), 0);
    });

    test('consecutive points of a session are connected', () async {
      final query = FogQuery(store);
      final end = offsetMeters(krakowLat, krakowLng, east: 200);
      final middle = offsetMeters(krakowLat, krakowLng, east: 100);

      await _apply(store, 'a', krakowLat, krakowLng);
      await _apply(store, 'a', end.lat, end.lng);

      expect(await query.coverageAt(middle.lat, middle.lng), 1);
    });

    test('different sessions are never connected', () async {
      final query = FogQuery(store);
      final end = offsetMeters(krakowLat, krakowLng, east: 200);
      final middle = offsetMeters(krakowLat, krakowLng, east: 100);

      await _apply(store, 'a', krakowLat, krakowLng);
      await _apply(store, 'b', end.lat, end.lng);

      expect(await query.coverageAt(middle.lat, middle.lng), 0);
    });

    test('applying the same point twice changes nothing', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();
      final area = store.totalAreaM2;
      final before = await decodeAllTiles(storage, FogConfig.baseZoom);

      await _apply(store, 'b', krakowLat, krakowLng);
      await store.flush();

      expect(store.totalAreaM2, closeTo(area, 1e-6));
      expect(
        sameMasks(before, await decodeAllTiles(storage, FogConfig.baseZoom)),
        isTrue,
      );
    });

    test('calls made without awaiting are applied in order', () async {
      final futures = <Future<void>>[];
      for (final entry in walkEast('a', points: 30)) {
        futures.add(
          store.applyPoint(
            sessionId: 'a',
            latitude: entry.latitude,
            longitude: entry.longitude,
          ),
        );
      }
      await Future.wait(futures);
      await store.flush();

      final sequential = await _open(InMemoryFogTileStorage());
      for (final entry in walkEast('a', points: 30)) {
        await _apply(sequential, 'a', entry.latitude, entry.longitude);
      }
      await sequential.flush();

      expect(store.totalAreaM2, closeTo(sequential.totalAreaM2, 1e-6));
      await sequential.dispose();
    });

    test(
      'a disc whose soft rim just reaches the next tile is drawn there',
      () async {
        final radius = metersToPixels(
          meters: 30,
          latitude: krakowLat,
          zoom: FogConfig.baseZoom.toDouble(),
        );
        final border =
            (FogMercator.lngToX(krakowLng, FogConfig.baseZoom) / 256).ceil() *
            256;
        final lng = FogMercator.xToLng(
          border - radius - 0.1,
          FogConfig.baseZoom,
        );

        await _apply(store, 'a', krakowLat, lng);
        await store.flush();

        final right = tileOf(
          krakowLat,
          FogMercator.xToLng(border + 0.5, FogConfig.baseZoom),
          FogConfig.baseZoom,
        );
        final mask = await store.maskFor(right);
        expect(mask, isNotNull);
        expect(mask!.at(0, _rowOf(krakowLat)), greaterThan(0));
      },
    );

    test('the area of a single disc matches the circle', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();

      const expected = math.pi * 30 * 30;
      expect(store.totalAreaM2, closeTo(expected, expected * 0.03));
    });

    test('the area of a walk matches the capsule', () async {
      for (final e in walkEast('a', points: 21)) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();

      const expected = 2 * 30 * 200 + math.pi * 30 * 30;
      expect(store.totalAreaM2, closeTo(expected, expected * 0.03));
    });
  });

  group('flushing', () {
    test('writes the base tile, its ancestors and the metadata', () async {
      await _apply(store, 'a', krakowLat, krakowLng);

      await store.flush();

      final stats = await storage.stats();
      expect(stats.tilesPerLevel[FogConfig.baseZoom], greaterThanOrEqualTo(1));
      for (var z = 4; z <= FogConfig.baseZoom; z++) {
        expect(stats.tilesPerLevel[z], isNotNull, reason: 'level $z');
      }
      expect(stats.tilesPerLevel[3], isNull);
      final meta = await storage.loadMeta();
      expect(meta['rev'], 1);
      expect(meta['baseZoom'], FogConfig.baseZoom);
      expect(meta['totalAreaM2'], closeTo(store.totalAreaM2, 1e-6));
      expect(store.revision, 1);
    });

    test('a flush with nothing to write does not bump the revision', () async {
      await store.flush();
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();
      await store.flush();

      expect(store.revision, 1);
    });

    test(
      'every flush stamps the tiles it wrote with a newer revision',
      () async {
        await _apply(store, 'a', krakowLat, krakowLng);
        await store.flush();
        final far = offsetMeters(krakowLat, krakowLng, east: 5000);
        await _apply(store, 'b', far.lat, far.lng);
        await store.flush();

        final changed = await storage.changedSince(1);

        expect(store.revision, 2);
        expect(changed.every((t) => t.rev == 2), isTrue);
        expect(changed.any((t) => t.id.z == FogConfig.baseZoom), isTrue);
      },
    );

    test('flushes by itself when too many tiles are waiting', () async {
      final small = await _open(InMemoryFogTileStorage(), maxDirtyTiles: 6);
      for (final e in walkEast('a', points: 120, stepMeters: 20)) {
        await _apply(small, 'a', e.latitude, e.longitude);
      }

      expect(small.revision, greaterThan(0));
      expect(small.diagnostics.dirtyTiles, lessThan(6));
      await small.dispose();
    });

    test(
      'a long route still reads back correctly after tiles are evicted',
      () async {
        final tiny = InMemoryFogTileStorage();
        final small = await _open(tiny, maxCachedTiles: 8, maxDirtyTiles: 4);
        final entries = walkEast('a', points: 400, stepMeters: 25);
        for (final e in entries) {
          await _apply(small, 'a', e.latitude, e.longitude);
        }
        await small.flush();

        final reference = await _open(InMemoryFogTileStorage());
        for (final e in entries) {
          await _apply(reference, 'a', e.latitude, e.longitude);
        }
        await reference.flush();

        expect(small.diagnostics.cachedTiles, lessThanOrEqualTo(12));
        expect(small.totalAreaM2, closeTo(reference.totalAreaM2, 1e-3));
        expect(
          sameMasks(
            await decodeAllTiles(tiny, FogConfig.baseZoom),
            await decodeAllTiles(
              await _storageOf(reference),
              FogConfig.baseZoom,
            ),
          ),
          isTrue,
        );
        await small.dispose();
        await reference.dispose();
      },
    );

    test('emits the changed tiles after applying and after flushing', () async {
      final changes = <FogChange>[];
      final sub = store.changes.listen(changes.add);

      await _apply(store, 'a', krakowLat, krakowLng);
      await pumpEventQueue();
      final afterApply = List.of(changes);
      await store.flush();
      await pumpEventQueue();
      await sub.cancel();

      expect(
        afterApply.single.tiles.every((t) => t.z == FogConfig.baseZoom),
        isTrue,
      );
      expect(
        changes.last.tiles.map((t) => t.z).toSet(),
        containsAll([4, 10, FogConfig.baseZoom]),
      );
    });
  });

  group('compact storage', () {
    test('base tiles hold 16 levels and overview tiles 8', () async {
      for (final e in walkEast('a', points: 40, stepMeters: 20)) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();

      final tiles = await storage.changedSince(0);
      var checked = 0;
      for (final tile in tiles) {
        final mask = FogTileCodec.decode(tile.flag, tile.bytes);
        final step = tile.id.z == FogConfig.baseZoom ? 16 : 32;
        for (final value in mask.data) {
          if (value == 255) continue;
          expect(value % step, 0, reason: 'level ${tile.id.z}');
        }
        checked++;
      }
      expect(checked, greaterThan(10));
    });

    test('encoding many tiles in an isolate gives the same bytes', () async {
      final entries = walkEast('a', points: 400, stepMeters: 25);
      final inline = InMemoryFogTileStorage();
      final withIsolate = InMemoryFogTileStorage();
      final a = await FogStore.open(
        inline,
        flushDelay: const Duration(hours: 1),
        encodeInIsolate: false,
      );
      final b = await FogStore.open(
        withIsolate,
        flushDelay: const Duration(hours: 1),
        isolateEncodeThreshold: 4,
      );

      await a.importEntries(entries, useIsolate: false);
      await b.importEntries(entries, useIsolate: false);
      await a.flush();
      await b.flush();

      expect(b.totalAreaM2, closeTo(a.totalAreaM2, 1e-6));
      final first = await inline.changedSince(0, limit: 1 << 20);
      final second = await withIsolate.changedSince(0, limit: 1 << 20);
      expect(second.length, first.length);
      expect(first.length, greaterThan(8));
      final bytes = {for (final t in first) t.id.key: t.bytes};
      for (final tile in second) {
        expect(tile.bytes, bytes[tile.id.key], reason: '${tile.id}');
      }
      await a.dispose();
      await b.dispose();
    });
  });

  group('overview pyramid', () {
    test('a thin trail stays visible on coarse levels', () async {
      for (final e in walkEast('a', points: 40, stepMeters: 20)) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();

      for (final z in [14, 11, 8, 5]) {
        final id = tileOf(krakowLat, krakowLng, z);
        await store.prepare(z, id.x, id.x, id.y, id.y);
        final mask = store.peek(id);
        expect(mask, isNotNull, reason: 'level $z');
        final strongest = mask!.data.reduce(math.max);
        expect(strongest, greaterThanOrEqualTo(128), reason: 'level $z');
      }
    });
  });

  group('persistence', () {
    test('a reopened store sees the same fog and totals', () async {
      for (final e in walkEast('a', points: 30)) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();
      final area = store.totalAreaM2;

      final reopened = await _open(storage);
      final query = FogQuery(reopened);
      final point = offsetMeters(krakowLat, krakowLng, east: 150);

      expect(reopened.totalAreaM2, closeTo(area, 1e-6));
      expect(reopened.revision, store.revision);
      expect(await query.coverageAt(point.lat, point.lng), 1);
      await reopened.dispose();
    });

    test('a store opened with another base zoom starts clean', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();

      final other = await _open(storage, baseZoom: FogConfig.baseZoom - 1);

      expect(other.totalAreaM2, 0);
      expect((await storage.stats()).tileCount, 0);
      await other.dispose();
    });

    test('clear forgets everything', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();

      await store.clear();

      expect((await storage.stats()).tileCount, 0);
      expect(store.totalAreaM2, 0);
      expect(store.revision, 0);
      expect(await FogQuery(store).coverageAt(krakowLat, krakowLng), 0);
    });
  });

  group('reading tiles', () {
    test('prepare marks tiles without fog data as known absent', () async {
      final id = tileOf(krakowLat, krakowLng, 12);

      await store.prepare(12, id.x, id.x + 1, id.y, id.y + 1);

      expect(store.isKnownAbsent(id), isTrue);
      expect(store.peek(id), isNull);
    });

    test('peek returns tiles loaded from storage', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();
      final reopened = await _open(storage);
      final id = tileOf(krakowLat, krakowLng, FogConfig.baseZoom);

      expect(reopened.peek(id), isNull);
      await reopened.prepare(FogConfig.baseZoom, id.x, id.x, id.y, id.y);

      expect(reopened.peek(id), isNotNull);
      expect(reopened.isKnownAbsent(id), isFalse);
      await reopened.dispose();
    });
  });

  group('track log replay', () {
    Future<(InMemoryTrackLogStorage, List<int>)> logWithTwoWalks() async {
      final log = InMemoryTrackLogStorage();
      final stored = await log.appendAll([
        ...walkEast('first', points: 30),
        ...walkEast('second', points: 30, startLat: krakowLat + 0.01),
      ]);
      return (log, [for (final e in stored) e.id!]);
    }

    test('rebuilding from the log equals applying live', () async {
      final (log, _) = await logWithTwoWalks();
      for (final e in await log.entriesAfter(0)) {
        await _apply(store, e.sessionId, e.latitude, e.longitude);
      }
      await store.flush();

      final rebuilt = InMemoryFogTileStorage();
      final other = await _open(rebuilt);
      await other.rebuildFrom(log, useIsolate: false);

      expect(other.totalAreaM2, closeTo(store.totalAreaM2, 1e-6));
      expect(
        sameMasks(
          await decodeAllTiles(storage, FogConfig.baseZoom),
          await decodeAllTiles(rebuilt, FogConfig.baseZoom),
        ),
        isTrue,
      );
      await other.dispose();
    });

    test('recovers the points lost in a crash without duplicating', () async {
      final (log, ids) = await logWithTwoWalks();
      final entries = await log.entriesAfter(0);

      for (var i = 0; i < 20; i++) {
        await store.applyPoint(
          sessionId: entries[i].sessionId,
          latitude: entries[i].latitude,
          longitude: entries[i].longitude,
          logId: ids[i],
        );
      }
      await store.flush();
      for (var i = 20; i < 40; i++) {
        await store.applyPoint(
          sessionId: entries[i].sessionId,
          latitude: entries[i].latitude,
          longitude: entries[i].longitude,
          logId: ids[i],
        );
      }
      // The process dies here: the store is dropped without a flush.

      final recovered = await _open(storage);
      expect(recovered.lastAppliedLogId, ids[19]);
      await recovered.replayFrom(log, useIsolate: false);

      final reference = InMemoryFogTileStorage();
      final expected = await _open(reference);
      await expected.rebuildFrom(log, useIsolate: false);

      expect(recovered.lastAppliedLogId, ids.last);
      expect(recovered.totalAreaM2, closeTo(expected.totalAreaM2, 1e-6));
      expect(
        sameMasks(
          await decodeAllTiles(storage, FogConfig.baseZoom),
          await decodeAllTiles(reference, FogConfig.baseZoom),
        ),
        isTrue,
      );
      await recovered.dispose();
      await expected.dispose();
    });

    test(
      'replay connects the first new point to the last applied one',
      () async {
        final log = InMemoryTrackLogStorage();
        final first = offsetMeters(krakowLat, krakowLng);
        final second = offsetMeters(krakowLat, krakowLng, east: 300);
        final stored = await log.appendAll([
          logEntry('a', 0, first),
          logEntry('a', 1, second),
        ]);
        await store.applyPoint(
          sessionId: 'a',
          latitude: first.lat,
          longitude: first.lng,
          logId: stored[0].id,
        );
        await store.flush();

        final recovered = await _open(storage);
        await recovered.replayFrom(log, useIsolate: false);
        final middle = offsetMeters(krakowLat, krakowLng, east: 150);

        expect(await FogQuery(recovered).coverageAt(middle.lat, middle.lng), 1);
        await recovered.dispose();
      },
    );

    test('replay on an up to date store does nothing', () async {
      final (log, ids) = await logWithTwoWalks();
      for (final e in await log.entriesAfter(0)) {
        await store.applyPoint(
          sessionId: e.sessionId,
          latitude: e.latitude,
          longitude: e.longitude,
          logId: e.id,
        );
      }
      await store.flush();
      final revision = store.revision;

      await store.replayFrom(log, useIsolate: false);

      expect(store.revision, revision);
      expect(store.lastAppliedLogId, ids.last);
    });
  });

  group('positions logged during a replay', () {
    final far = offsetMeters(krakowLat, krakowLng, north: 2000);

    test('a crash during the replay loses no log entries', () async {
      final log = _PausingTrackLog();
      await log.appendAll(walkEast('a', points: 30));
      log.pauseAt = _LogCall.entriesAfter;

      final replay = store.replayFrom(log, useIsolate: false);
      await log.paused.future;
      final live = await log.append(logEntry('a', 30, far));
      final applied = _applyLogged(store, live);
      await store.flush();

      // The process dies here; the next start replays from what was stored.
      final recovered = await _open(storage);
      await recovered.replayFrom(log, useIsolate: false);
      final walked = offsetMeters(krakowLat, krakowLng, east: 150);
      expect(await FogQuery(recovered).coverageAt(walked.lat, walked.lng), 1);
      await recovered.dispose();

      log.resume();
      await replay;
      await applied;
      expect(store.lastAppliedLogId, live.id);
    });

    test(
      'a new position does not connect to the start of the replay',
      () async {
        final log = _PausingTrackLog();
        await log.appendAll([
          for (var i = 0; i <= 3; i++)
            logEntry(
              'a',
              i,
              offsetMeters(krakowLat, krakowLng, north: i * 100),
            ),
        ]);
        log.pauseAt = _LogCall.entriesAfter;

        final replay = store.replayFrom(log, useIsolate: false);
        await log.paused.future;
        final east = offsetMeters(krakowLat, krakowLng, east: 600);
        final applied = _applyLogged(
          store,
          await log.append(logEntry('a', 4, east)),
        );
        log.resume();
        await replay;
        await applied;

        final query = FogQuery(store);
        final backToStart = offsetMeters(krakowLat, krakowLng, east: 300);
        final lastLeg = offsetMeters(
          krakowLat,
          krakowLng,
          north: 150,
          east: 300,
        );
        expect(await query.coverageAt(backToStart.lat, backToStart.lng), 0);
        expect(await query.coverageAt(lastLeg.lat, lastLeg.lng), 1);
      },
    );

    test('a rebuild draws the whole log when a position is logged right after '
        'the tiles were cleared', () async {
      final log = _PausingTrackLog();
      await log.appendAll(walkEast('a', points: 30));
      log.pauseAt = _LogCall.count;

      final rebuild = store.rebuildFrom(log, useIsolate: false);
      await log.paused.future;
      final applied = _applyLogged(
        store,
        await log.append(logEntry('a', 30, far)),
      );
      await store.flush();
      log.resume();
      await rebuild;
      await applied;

      final walked = offsetMeters(krakowLat, krakowLng, east: 150);
      expect(await FogQuery(store).coverageAt(walked.lat, walked.lng), 1);
    });
  });

  group('a failed replay', () {
    final far = offsetMeters(krakowLat, krakowLng, north: 2000);
    final walked = offsetMeters(krakowLat, krakowLng, east: 150);

    test('new positions do not move the replay position', () async {
      final log = _FailingOnceTrackLog();
      await log.appendAll(walkEast('a', points: 30));
      await expectLater(
        store.replayFrom(log, useIsolate: false),
        throwsStateError,
      );

      final live = await log.append(logEntry('b', 0, far));
      await _applyLogged(store, live);
      await store.flush();

      expect(store.lastAppliedLogId, 0);
      final restarted = await _open(storage);
      await restarted.replayFrom(log, useIsolate: false);
      expect(await FogQuery(restarted).coverageAt(walked.lat, walked.lng), 1);
      await restarted.dispose();
    });

    test('a later successful replay moves the replay position again', () async {
      final log = _FailingOnceTrackLog();
      await log.appendAll(walkEast('a', points: 30));
      await expectLater(
        store.replayFrom(log, useIsolate: false),
        throwsStateError,
      );

      await store.replayFrom(log, useIsolate: false);
      final live = await log.append(logEntry('b', 0, far));
      await _applyLogged(store, live);

      expect(store.lastAppliedLogId, live.id);
    });
  });

  group('importing entries', () {
    test('equals applying one point at a time', () async {
      final entries = [
        ...walkEast('a', points: 80, stepMeters: 15),
        ...walkEast('b', points: 50, startLat: krakowLat + 0.003),
      ];
      for (final e in entries) {
        await _apply(store, e.sessionId, e.latitude, e.longitude);
      }
      await store.flush();

      final importedStorage = InMemoryFogTileStorage();
      final imported = await _open(importedStorage);
      await imported.importEntries(entries, useIsolate: false, chunkSize: 37);
      await imported.flush();

      expect(imported.totalAreaM2, closeTo(store.totalAreaM2, 1e-3));
      expect(
        sameMasks(
          await decodeAllTiles(storage, FogConfig.baseZoom),
          await decodeAllTiles(importedStorage, FogConfig.baseZoom),
        ),
        isTrue,
      );
      await imported.dispose();
    });

    test('works through a background isolate too', () async {
      final entries = walkEast('a', points: 60, stepMeters: 15);
      final importedStorage = InMemoryFogTileStorage();
      final imported = await _open(importedStorage);

      await imported.importEntries(entries, chunkSize: 25);
      await imported.flush();

      const expected = 2 * 30 * 59 * 15 + math.pi * 30 * 30;
      expect(imported.totalAreaM2, closeTo(expected, expected * 0.03));
      await imported.dispose();
    });

    test('reports progress', () async {
      final progress = <double>[];

      await store.importEntries(
        walkEast('a', points: 50),
        useIsolate: false,
        chunkSize: 20,
        onProgress: progress.add,
      );

      expect(progress.last, 1);
      expect(progress.length, 3);
    });
  });

  group('FogQuery', () {
    test('coverage along a polyline is the covered share', () async {
      for (final e in walkEast('a', points: 21)) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      final query = FogQuery(store);
      final route = [
        const LatLng(krakowLat, krakowLng),
        LatLng(
          offsetMeters(krakowLat, krakowLng, east: 400).lat,
          offsetMeters(krakowLat, krakowLng, east: 400).lng,
        ),
      ];

      final fraction = await query.coveredFractionAlong(route);

      expect(fraction, closeTo(0.5, 0.1));
    });

    test('a route far from the fog has no coverage', () async {
      await _apply(store, 'a', krakowLat, krakowLng);

      final fraction = await FogQuery(store).coveredFractionAlong([
        const LatLng(krakowLat + 1, krakowLng),
        const LatLng(krakowLat + 1.01, krakowLng),
      ]);

      expect(fraction, 0);
    });

    test('an empty route has no coverage', () async {
      expect(await FogQuery(store).coveredFractionAlong(const []), 0);
    });

    test('covered area inside bounds matches the total for a disc', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      final query = FogQuery(store);
      final northEast = offsetMeters(krakowLat, krakowLng, north: 80, east: 80);
      final southWest = offsetMeters(
        krakowLat,
        krakowLng,
        north: -80,
        east: -80,
      );

      final area = await query.coveredAreaM2(
        south: southWest.lat,
        west: southWest.lng,
        north: northEast.lat,
        east: northEast.lng,
      );

      expect(area, closeTo(math.pi * 30 * 30, math.pi * 30 * 30 * 0.03));
    });

    test('covered area of half the disc is about half', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      final query = FogQuery(store);
      final northEast = offsetMeters(krakowLat, krakowLng, north: 80, east: 80);
      final southWest = offsetMeters(krakowLat, krakowLng, east: -80);

      final area = await query.coveredAreaM2(
        south: southWest.lat,
        west: southWest.lng,
        north: northEast.lat,
        east: northEast.lng,
      );

      expect(area, closeTo(math.pi * 30 * 30 / 2, math.pi * 30 * 30 * 0.04));
    });

    test('total discovered area is reported in square kilometers', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();

      expect(
        FogQuery(store).totalDiscoveredKm2,
        closeTo(store.totalAreaM2 / 1e6, 1e-12),
      );
    });
  });

  test('tile ids of a fresh store are not cached', () async {
    expect(store.peek(const FogTileId(FogConfig.baseZoom, 1, 1)), isNull);
    expect(
      store.isKnownAbsent(const FogTileId(FogConfig.baseZoom, 1, 1)),
      isFalse,
    );
    expect(store.diagnostics.cachedTiles, 0);
    expect(FogMask.pixels, 65536);
  });
  group('drawing over what is already there', () {
    test('an identical second pass leaves nothing to write', () async {
      for (final e in walkEast('a')) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();
      final revision = store.revision;

      for (final e in walkEast('b')) {
        await _apply(store, 'b', e.latitude, e.longitude);
      }

      expect(store.diagnostics.dirtyTiles, 0);
      await store.flush();
      expect(store.revision, revision);
      expect(await storage.changedSince(revision), isEmpty);
    });

    test('a pass that adds something is still written', () async {
      for (final e in walkEast('a')) {
        await _apply(store, 'a', e.latitude, e.longitude);
      }
      await store.flush();
      final revision = store.revision;

      for (final e in walkEast('b', points: 30)) {
        await _apply(store, 'b', e.latitude, e.longitude);
      }
      await store.flush();

      expect(store.revision, revision + 1);
      expect(await storage.changedSince(revision), isNotEmpty);
    });

    test('walking the same loop again does not raise the revision', () async {
      Future<void> lap(String session) async {
        for (var i = 0; i <= 36; i++) {
          final angle = 2 * math.pi * i / 36;
          final at = offsetMeters(
            krakowLat,
            krakowLng,
            north: 60 * math.sin(angle),
            east: 60 * math.cos(angle),
          );
          await _apply(store, session, at.lat, at.lng);
        }
        await store.flush();
      }

      await lap('a');
      final afterFirst = store.revision;
      await lap('b');
      final afterSecond = store.revision;
      await lap('c');
      await lap('d');

      expect(afterSecond, afterFirst);
      expect(store.revision, afterFirst);
    });

    test('no change is announced for an unchanged pass', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();
      final changes = <FogChange>[];
      final sub = store.changes.listen(changes.add);

      await _apply(store, 'b', krakowLat, krakowLng);
      await pumpEventQueue();
      await sub.cancel();

      expect(changes, isEmpty);
    });

    test('a changed pass is announced with only the changed tiles', () async {
      await _apply(store, 'a', krakowLat, krakowLng);
      await store.flush();
      final changes = <FogChange>[];
      final sub = store.changes.listen(changes.add);

      final away = offsetMeters(krakowLat, krakowLng, east: 500);
      await _apply(store, 'b', away.lat, away.lng);
      await pumpEventQueue();
      await sub.cancel();

      expect(changes.single.tiles, isNotEmpty);
      expect(
        changes.single.tiles.contains(
          tileOf(krakowLat, krakowLng, FogConfig.baseZoom),
        ),
        isFalse,
      );
    });

    test('the log position is still saved when no tile changed', () async {
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
        logId: 1,
      );
      await store.flush();

      await store.applyPoint(
        sessionId: 'b',
        latitude: krakowLat,
        longitude: krakowLng,
        logId: 2,
      );
      await store.flush();

      expect((await storage.loadMeta())['lastAppliedLogId'], 2);
      expect(store.lastAppliedLogId, 2);
    });

    test('importing entries that are already drawn writes nothing', () async {
      final entries = walkEast('a', points: 60, stepMeters: 15);
      await store.importEntries(entries, useIsolate: false);
      await store.flush();
      final revision = store.revision;
      final area = store.totalAreaM2;

      await store.importEntries(
        walkEast('b', points: 60, stepMeters: 15),
        useIsolate: false,
      );
      await store.flush();

      expect(store.revision, revision);
      expect(store.totalAreaM2, area);
      expect(store.diagnostics.dirtyTiles, 0);
    });

    test('an already drawn log replays without any write', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a', points: 40));
      await store.replayFrom(log, useIsolate: false);
      final revision = store.revision;
      final tiles = (await storage.stats()).tileCount;

      final reopened = await _open(storage);
      await reopened.rebuildFrom(log, useIsolate: false);
      final rebuilt = reopened.revision;
      await reopened.replayFrom(log, useIsolate: false);

      expect(reopened.revision, rebuilt);
      expect((await storage.stats()).tileCount, tiles);
      expect(revision, greaterThan(0));
      await reopened.dispose();
    });
  });
}

Future<FogTileStorage> _storageOf(FogStore store) async => store.storage;
