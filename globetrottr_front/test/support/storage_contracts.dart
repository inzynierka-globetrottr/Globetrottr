import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

StoredFogTile _tile(
  int z,
  int x,
  int y, {
  int flag = 2,
  int rev = 1,
  double area = 0,
  List<int>? bytes,
}) {
  return StoredFogTile(
    id: FogTileId(z, x, y),
    flag: flag,
    rev: rev,
    areaM2: area,
    bytes: flag == 2 ? Uint8List.fromList(bytes ?? [1, 2, 3, 250, 0]) : null,
  );
}

void runFogTileStorageContract(
  String name,
  Future<FogTileStorage> Function() create,
) {
  group('FogTileStorage contract: $name', () {
    late FogTileStorage storage;

    setUp(() async {
      storage = await create();
    });

    tearDown(() => storage.close());

    test('starts empty', () async {
      expect(await storage.loadTiles([const FogTileId(5, 1, 1)]), isEmpty);
      expect(await storage.loadMeta(), isEmpty);
      final stats = await storage.stats();
      expect(stats.tileCount, 0);
      expect(stats.totalBytes, 0);
    });

    test('returns committed tiles byte for byte', () async {
      final bytes = List<int>.generate(300, (i) => (i * 7) % 256);
      await storage.commit(
        upserts: [_tile(17, 72793, 44421, rev: 3, area: 12.5, bytes: bytes)],
        meta: const {},
      );

      final loaded = await storage.loadTiles([
        const FogTileId(17, 72793, 44421),
      ]);

      expect(loaded.single.id, const FogTileId(17, 72793, 44421));
      expect(loaded.single.flag, 2);
      expect(loaded.single.rev, 3);
      expect(loaded.single.areaM2, 12.5);
      expect(loaded.single.bytes, bytes);
    });

    test('flag-only tiles have no payload', () async {
      await storage.commit(
        upserts: [_tile(5, 1, 1, flag: 1)],
        meta: const {},
      );

      final loaded = await storage.loadTiles([const FogTileId(5, 1, 1)]);

      expect(loaded.single.flag, 1);
      expect(loaded.single.bytes, isNull);
    });

    test('only returns tiles that exist', () async {
      await storage.commit(upserts: [_tile(5, 1, 1)], meta: const {});

      final loaded = await storage.loadTiles([
        const FogTileId(5, 1, 1),
        const FogTileId(5, 2, 2),
      ]);

      expect(loaded.map((t) => t.id), [const FogTileId(5, 1, 1)]);
    });

    test('loads many ids at once', () async {
      await storage.commit(
        upserts: [for (var x = 0; x < 400; x++) _tile(12, x, 7)],
        meta: const {},
      );

      final loaded = await storage.loadTiles([
        for (var x = 0; x < 400; x++) FogTileId(12, x, 7),
      ]);

      expect(loaded.length, 400);
    });

    test('a later commit replaces the tile', () async {
      await storage.commit(
        upserts: [
          _tile(5, 1, 1, bytes: [1]),
        ],
        meta: const {},
      );
      await storage.commit(
        upserts: [
          _tile(5, 1, 1, rev: 2, bytes: [9, 9]),
        ],
        meta: const {},
      );

      final loaded = await storage.loadTiles([const FogTileId(5, 1, 1)]);

      expect(loaded.single.rev, 2);
      expect(loaded.single.bytes, [9, 9]);
    });

    test(
      'loadRange returns tiles of one level inside the range only',
      () async {
        await storage.commit(
          upserts: [
            _tile(8, 10, 10),
            _tile(8, 11, 12),
            _tile(8, 13, 10),
            _tile(8, 10, 14),
            _tile(9, 10, 10),
          ],
          meta: const {},
        );

        final loaded = await storage.loadRange(
          z: 8,
          xMin: 10,
          xMax: 12,
          yMin: 10,
          yMax: 13,
        );

        expect(
          loaded.map((t) => t.id).toSet(),
          {const FogTileId(8, 10, 10), const FogTileId(8, 11, 12)},
        );
      },
    );

    test('changedSince returns tiles with a newer revision', () async {
      await storage.commit(
        upserts: [_tile(5, 1, 1), _tile(5, 2, 2, rev: 4)],
        meta: const {},
      );

      final changed = await storage.changedSince(2);

      expect(changed.map((t) => t.id), [const FogTileId(5, 2, 2)]);
    });

    test('meta is written together with the tiles and overwritten', () async {
      await storage.commit(
        upserts: [_tile(5, 1, 1)],
        meta: const {'rev': 1, 'area': 10.5},
      );
      await storage.commit(upserts: const [], meta: const {'rev': 2});

      final meta = await storage.loadMeta();

      expect(meta['rev'], 2);
      expect(meta['area'], 10.5);
    });

    test('stats count tiles and payload bytes per level', () async {
      await storage.commit(
        upserts: [
          _tile(5, 1, 1, bytes: [1, 2, 3]),
          _tile(5, 2, 2, bytes: [1, 2]),
          _tile(6, 2, 2, flag: 1),
        ],
        meta: const {},
      );

      final stats = await storage.stats();

      expect(stats.tileCount, 3);
      expect(stats.totalBytes, 5);
      expect(stats.tilesPerLevel, {5: 2, 6: 1});
    });

    test('clear removes tiles and meta', () async {
      await storage.commit(
        upserts: [_tile(5, 1, 1)],
        meta: const {'rev': 1},
      );

      await storage.clear();

      expect(await storage.loadTiles([const FogTileId(5, 1, 1)]), isEmpty);
      expect(await storage.loadMeta(), isEmpty);
    });
  });
}

TrackLogEntry _entry(
  String session,
  int ts, {
  double lat = 50,
  double lng = 19,
  double? accuracy,
  double? speed,
}) {
  return TrackLogEntry(
    sessionId: session,
    timestampMs: ts,
    latitude: lat,
    longitude: lng,
    accuracy: accuracy,
    speed: speed,
  );
}

void runTrackLogStorageContract(
  String name,
  Future<TrackLogStorage> Function() create,
) {
  group('TrackLogStorage contract: $name', () {
    late TrackLogStorage storage;

    setUp(() async {
      storage = await create();
    });

    tearDown(() => storage.close());

    test('append assigns increasing ids and keeps every field', () async {
      final first = await storage.append(
        _entry('a', 1000, lat: 50.1, lng: 19.2, accuracy: 4.5, speed: 1.25),
      );
      final second = await storage.append(_entry('a', 2000));

      expect(first.id, isNotNull);
      expect(second.id, greaterThan(first.id!));
      final stored = (await storage.entriesAfter(0)).first;
      expect(stored.sessionId, 'a');
      expect(stored.timestampMs, 1000);
      expect(stored.latitude, 50.1);
      expect(stored.longitude, 19.2);
      expect(stored.accuracy, 4.5);
      expect(stored.speed, 1.25);
    });

    test('optional fields stay null', () async {
      await storage.append(_entry('a', 1));

      final stored = (await storage.entriesAfter(0)).single;

      expect(stored.accuracy, isNull);
      expect(stored.speed, isNull);
    });

    test('appendAll stores everything in order and returns the ids', () async {
      final stored = await storage.appendAll([
        for (var i = 0; i < 25; i++) _entry('a', 1000 + i),
      ]);

      expect(stored.length, 25);
      expect(stored.map((e) => e.id).toSet().length, 25);
      expect(await storage.count(), 25);
      final all = await storage.entriesAfter(0, limit: 100);
      expect(all.map((e) => e.timestampMs), [
        for (var i = 0; i < 25; i++) 1000 + i,
      ]);
    });

    test('entriesAfter is ordered by id and respects the limit', () async {
      final stored = await storage.appendAll([
        for (var i = 0; i < 10; i++) _entry('a', i),
      ]);

      final page = await storage.entriesAfter(stored[3].id!, limit: 4);

      expect(page.map((e) => e.timestampMs), [4, 5, 6, 7]);
    });

    test('entriesBetween filters by time inclusively', () async {
      await storage.appendAll([
        _entry('a', 100),
        _entry('a', 200),
        _entry('b', 300),
        _entry('b', 400),
      ]);

      final range = await storage.entriesBetween(200, 300);

      expect(range.map((e) => e.timestampMs), [200, 300]);
    });

    test(
      'lastEntryOfSession finds the previous point of that session',
      () async {
        final stored = await storage.appendAll([
          _entry('a', 1),
          _entry('b', 2),
          _entry('a', 3),
          _entry('b', 4),
        ]);

        final last = await storage.lastEntryOfSession(
          'a',
          atOrBeforeId: stored[2].id!,
        );
        final earlier = await storage.lastEntryOfSession(
          'a',
          atOrBeforeId: stored[1].id!,
        );
        final none = await storage.lastEntryOfSession('c', atOrBeforeId: 999);

        expect(last!.timestampMs, 3);
        expect(earlier!.timestampMs, 1);
        expect(none, isNull);
      },
    );

    test('session summaries group points by session in time order', () async {
      await storage.appendAll([
        _entry('late', 5000),
        _entry('early', 1000),
        _entry('early', 3000),
        _entry('late', 9000),
        _entry('late', 7000),
      ]);

      final sessions = await storage.sessionSummaries();

      expect(sessions.map((s) => s.sessionId), ['early', 'late']);
      expect(sessions[0].startMs, 1000);
      expect(sessions[0].endMs, 3000);
      expect(sessions[0].pointCount, 2);
      expect(sessions[1].startMs, 5000);
      expect(sessions[1].endMs, 9000);
      expect(sessions[1].pointCount, 3);
    });

    test(
      'entriesInBounds returns the entries of the box ordered by id',
      () async {
        final stored = await storage.appendAll([
          _entry('a', 1),
          _entry('a', 2, lat: 50.5, lng: 19.5),
          _entry('a', 3, lat: 51.0, lng: 20.0),
          _entry('b', 4, lat: 50.2, lng: 19.2),
          _entry('b', 5, lat: 50.2, lng: 25.0),
          _entry('b', 6, lat: 40.0, lng: 19.2),
        ]);

        final inside = await storage.entriesInBounds(
          south: 49.9,
          west: 18.9,
          north: 50.6,
          east: 19.6,
        );

        expect(inside.map((e) => e.id), [
          stored[0].id,
          stored[1].id,
          stored[3].id,
        ]);
        expect(inside.map((e) => e.sessionId), ['a', 'a', 'b']);
      },
    );

    test('entriesInBounds includes points exactly on the border', () async {
      await storage.append(_entry('a', 1));

      final inside = await storage.entriesInBounds(
        south: 50.0,
        west: 19.0,
        north: 50.0,
        east: 19.0,
      );

      expect(inside.length, 1);
    });

    test('entriesInBounds keeps every field', () async {
      await storage.append(
        _entry('a', 77, lat: 50.1, lng: 19.2, accuracy: 3.5, speed: 2.5),
      );

      final entry = (await storage.entriesInBounds(
        south: 50,
        west: 19,
        north: 51,
        east: 20,
      )).single;

      expect(entry.id, isNotNull);
      expect(entry.timestampMs, 77);
      expect(entry.accuracy, 3.5);
      expect(entry.speed, 2.5);
    });

    test(
      'entriesInBounds respects the limit and keeps the oldest first',
      () async {
        final stored = await storage.appendAll([
          for (var i = 0; i < 10; i++) _entry('a', i, lat: 50.0 + i * 0.001),
        ]);

        final some = await storage.entriesInBounds(
          south: 49,
          west: 18,
          north: 52,
          east: 21,
          limit: 4,
        );

        expect(some.map((e) => e.id), [for (final e in stored.take(4)) e.id]);
      },
    );

    test('entriesInBounds is empty when nothing is inside', () async {
      await storage.append(_entry('a', 1));

      expect(
        await storage.entriesInBounds(south: 10, west: 10, north: 11, east: 11),
        isEmpty,
      );
    });

    test('append returns the entry as it is stored: rounded', () async {
      final stored = await storage.append(
        _entry(
          'a',
          5,
          lat: 50.123456789,
          lng: 19.987654321,
          accuracy: 4.5678,
          speed: 1.2345,
        ),
      );

      expect(stored.latitude, 50.1234568);
      expect(stored.longitude, 19.9876543);
      expect(stored.accuracy, 4.6);
      expect(stored.speed, 1.23);
      final read = (await storage.entriesAfter(0)).single;
      expect(read.latitude, stored.latitude);
      expect(read.longitude, stored.longitude);
      expect(read.accuracy, stored.accuracy);
      expect(read.speed, stored.speed);
    });

    test('a position that is not a real number is refused', () async {
      await expectLater(
        storage.append(_entry('a', 1, lat: double.nan)),
        throwsArgumentError,
      );
      await expectLater(
        storage.appendAll([
          _entry('a', 1),
          _entry('a', 2, lng: double.infinity),
        ]),
        throwsArgumentError,
      );
      expect(await storage.count(), 0);
    });

    test('compact changes nothing that can be read', () async {
      await storage.appendAll([
        for (var i = 0; i < 7; i++)
          _entry(i.isEven ? 'a' : 'b', i, lat: 50 + i * 0.001),
      ]);
      final before = await storage.entriesAfter(0, limit: 100);

      await storage.compact();
      await storage.compact();

      final after = await storage.entriesAfter(0, limit: 100);
      expect(after.map((e) => e.id), before.map((e) => e.id));
      expect(after.map((e) => e.latitude), before.map((e) => e.latitude));
      expect(await storage.count(), 7);
    });

    test('compact on an empty log is harmless', () async {
      await storage.compact();

      expect(await storage.count(), 0);
    });

    test('ids keep growing after the log is cleared', () async {
      final first = await storage.appendAll([_entry('a', 1), _entry('a', 2)]);

      await storage.clear();
      final next = await storage.append(_entry('b', 3));

      expect(next.id, greaterThan(first.last.id!));
      expect(await storage.lastId(), next.id);
    });

    test('lastId is zero when empty and the newest id otherwise', () async {
      expect(await storage.lastId(), 0);

      final stored = await storage.appendAll([_entry('a', 1), _entry('b', 2)]);

      expect(await storage.lastId(), stored.last.id);
    });

    test('clear removes everything', () async {
      await storage.appendAll([_entry('a', 1), _entry('a', 2)]);

      await storage.clear();

      expect(await storage.count(), 0);
      expect(await storage.entriesAfter(0), isEmpty);
    });
  });
}
