import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';
import '../../../support/in_memory_track_log_storage.dart';

Future<HeatStore> _open(InMemoryFogTileStorage storage) {
  return HeatStore.open(
    storage,
    encodeInIsolate: false,
    flushDelay: const Duration(hours: 1),
  );
}

Future<void> _applyAll(HeatStore store, List<TrackLogEntry> entries) async {
  for (final entry in entries) {
    await store.applyPoint(
      sessionId: entry.sessionId,
      latitude: entry.latitude,
      longitude: entry.longitude,
      logId: entry.id,
    );
  }
}

/// Sessions counted at one point of the base level.
Future<int> _countAt(HeatStore store, double lat, double lng) async {
  final tile = tileOf(lat, lng, store.baseZoom);
  await store.prepare(singleTile(tile));
  final counts = store.peek(tile);
  if (counts == null) return 0;
  final px = (FogMercator.lngToX(lng, store.baseZoom) - tile.x * 256).floor();
  final py = (FogMercator.latToY(lat, store.baseZoom) - tile.y * 256).floor();
  return counts.at(px, py);
}

Future<Map<int, FogMask>> _baseTiles(InMemoryFogTileStorage storage) async {
  final tiles = await storage.loadRange(
    z: FogConfig.baseZoom,
    xMin: 0,
    xMax: (1 << FogConfig.baseZoom) - 1,
    yMin: 0,
    yMax: (1 << FogConfig.baseZoom) - 1,
  );
  final store = await _open(storage);
  final result = <int, FogMask>{};
  for (final tile in tiles) {
    await store.prepare(singleTile(tile.id));
    result[tile.id.key] = store.peek(tile.id)!;
  }
  return result;
}

void main() {
  final middle = offsetMeters(krakowLat, krakowLng, east: 100);

  test('counts a place once per session, however often it is passed', () async {
    final store = await _open(InMemoryFogTileStorage());
    final there = walkEast('a', points: 21);
    final back = there.reversed.toList();

    await _applyAll(store, [...there, ...back, ...there]);

    expect(await _countAt(store, middle.lat, middle.lng), 1);
  });

  test('adds one for every session that passes a place', () async {
    final store = await _open(InMemoryFogTileStorage());

    for (final session in ['a', 'b', 'c']) {
      await _applyAll(store, walkEast(session, points: 21));
    }

    expect(await _countAt(store, middle.lat, middle.lng), 3);
    final far = offsetMeters(krakowLat, krakowLng, north: 500);
    expect(await _countAt(store, far.lat, far.lng), 0);
  });

  test('a rebuild from the track log gives the live result', () async {
    final log = InMemoryTrackLogStorage();
    final entries = await log.appendAll([
      ...walkEast('a', points: 40),
      ...walkEast('b', points: 30, startLat: krakowLat + 0.0003),
      ...walkEast('a', points: 40, firstIndex: 40).reversed,
    ]);
    final liveStorage = InMemoryFogTileStorage();
    final live = await _open(liveStorage);
    await _applyAll(live, entries);
    await live.flush();

    final rebuiltStorage = InMemoryFogTileStorage();
    final rebuilt = await _open(rebuiltStorage);
    await rebuilt.rebuildFrom(log, useIsolate: false);

    expect(
      sameMasks(
        await _baseTiles(liveStorage),
        await _baseTiles(rebuiltStorage),
      ),
      isTrue,
    );
    expect(rebuilt.diagnostics.lastAppliedLogId, entries.last.id);
  });

  test(
    'a restart in the middle of a session does not count it twice',
    () async {
      final log = InMemoryTrackLogStorage();
      final entries = await log.appendAll([
        ...walkEast('a', points: 21),
        ...walkEast('a', points: 21, firstIndex: 21).reversed,
      ]);
      final storage = InMemoryFogTileStorage();
      final first = await _open(storage);
      await _applyAll(first, entries.sublist(0, 21));
      await first.flush();

      final restarted = await _open(storage);
      await restarted.replayFrom(log, useIsolate: false);

      expect(await _countAt(restarted, middle.lat, middle.lng), 1);
      expect(restarted.diagnostics.lastAppliedLogId, entries.last.id);
    },
  );

  test('the zoomed out levels keep the busiest place', () async {
    final storage = InMemoryFogTileStorage();
    final store = await _open(storage);
    for (final session in ['a', 'b']) {
      await _applyAll(store, walkEast(session, points: 21));
    }
    await store.flush();

    final coarse = tileOf(middle.lat, middle.lng, FogConfig.minZoom);
    await store.prepare(singleTile(coarse));
    final counts = store.peek(coarse)!;

    expect(counts.data.reduce((a, b) => a > b ? a : b), 2);
  });

  test('a store drawn by an older version is cleared on open', () async {
    final storage = InMemoryFogTileStorage();
    final store = await _open(storage);
    await _applyAll(store, walkEast('a'));
    await store.flush();
    await storage.commit(upserts: const [], meta: {'heatVersion': -1});

    final reopened = await _open(storage);

    expect((await storage.stats()).tileCount, 0);
    expect(reopened.diagnostics.lastAppliedLogId, 0);
  });

  test('points logged during a replay wait for it, in log order', () async {
    final log = InMemoryTrackLogStorage();
    final entries = await log.appendAll(walkEast('a', points: 21));
    final store = await _open(InMemoryFogTileStorage());

    final replay = store.replayFrom(log, useIsolate: false);
    final late = await log.append(
      logEntry('b', 0, offsetMeters(krakowLat, krakowLng, east: 100)),
    );
    final applied = store.applyPoint(
      sessionId: late.sessionId,
      latitude: late.latitude,
      longitude: late.longitude,
      logId: late.id,
    );
    await Future.wait([replay, applied]);

    expect(await _countAt(store, middle.lat, middle.lng), 2);
    expect(store.diagnostics.lastAppliedLogId, late.id);
    expect(entries, hasLength(21));
  });

  test('changes report the base tiles a point counted', () async {
    final store = await _open(InMemoryFogTileStorage());
    final changes = <FogTileId>[];
    store.changes.listen((change) => changes.addAll(change.tiles));

    await _applyAll(store, walkEast('a', points: 2));
    await Future<void>.delayed(Duration.zero);

    expect(changes, isNotEmpty);
    expect(changes.every((id) => id.z == FogConfig.baseZoom), isTrue);
  });
}
