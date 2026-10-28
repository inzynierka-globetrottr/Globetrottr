import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/sqflite_track_log_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

TrackLogEntry _entry(
  String session,
  int ts, {
  double lat = 50,
  double lng = 19,
}) {
  return TrackLogEntry(
    sessionId: session,
    timestampMs: ts,
    latitude: lat,
    longitude: lng,
    accuracy: 4,
    speed: 1,
  );
}

List<TrackLogEntry> _walk(String session, int count, {int from = 0}) => [
  for (var i = 0; i < count; i++)
    _entry(session, 1000 * (from + i), lat: 50 + (from + i) * 0.0001),
];

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('track_blocks');
    path = '${dir.path}/tracks.db';
  });

  tearDown(() => dir.delete(recursive: true));

  SqfliteTrackLogStorage open({int blockSize = 4}) =>
      SqfliteTrackLogStorage(path: path, blockSize: blockSize);

  group('blocks and tail', () {
    test('points wait in the tail until a block is full', () async {
      final log = open();
      addTearDown(log.close);

      await log.append(_entry('a', 1));
      await log.append(_entry('a', 2));
      await log.append(_entry('a', 3));
      expect(await log.debugLayout(), (blocks: 0, tailRows: 3));

      await log.append(_entry('a', 4));
      expect(await log.debugLayout(), (blocks: 1, tailRows: 0));

      await log.append(_entry('a', 5));
      await log.append(_entry('a', 6));
      expect(await log.debugLayout(), (blocks: 1, tailRows: 2));
    });

    test('compact turns the tail into a block', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 3));

      await log.compact();

      expect(await log.debugLayout(), (blocks: 1, tailRows: 0));
    });

    test('a large batch goes straight into blocks', () async {
      final log = open();
      addTearDown(log.close);

      await log.appendAll(_walk('a', 10));

      expect(await log.debugLayout(), (blocks: 3, tailRows: 0));
      expect((await log.entriesAfter(0, limit: 100)).length, 10);
    });

    test('a large batch after a small one keeps the order', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 2));

      await log.appendAll(_walk('a', 9, from: 2));

      final all = await log.entriesAfter(0, limit: 100);
      expect(all.map((e) => e.id), [for (var i = 1; i <= 11; i++) i]);
      expect(all.map((e) => e.timestampMs), [
        for (var i = 0; i < 11; i++) i * 1000,
      ]);
    });

    test('reads the same whatever the block boundaries are', () async {
      final expected = _walk('a', 13);
      for (final size in [1, 2, 3, 4, 5, 13, 50]) {
        final file = '${dir.path}/size$size.db';
        final log = SqfliteTrackLogStorage(path: file, blockSize: size);
        for (var i = 0; i < expected.length; i += 3) {
          await log.appendAll(
            expected.sublist(i, (i + 3).clamp(0, expected.length)),
          );
        }

        final read = await log.entriesAfter(0, limit: 100);
        await log.close();

        expect(read.length, 13, reason: 'block size $size');
        expect(
          read.map((e) => e.latitude),
          [for (var i = 0; i < 13; i++) 50 + i * 0.0001],
          reason: 'block size $size',
        );
        expect(read.map((e) => e.id), [for (var i = 1; i <= 13; i++) i]);
      }
    });

    test(
      'interleaved sessions get their own blocks and stay in order',
      () async {
        final log = open();
        addTearDown(log.close);

        await log.appendAll([
          _entry('a', 1),
          _entry('b', 2),
          _entry('a', 3),
          _entry('b', 4),
          _entry('b', 5),
        ]);
        await log.compact();

        final all = await log.entriesAfter(0, limit: 100);
        expect(all.map((e) => e.sessionId), ['a', 'b', 'a', 'b', 'b']);
        expect(all.map((e) => e.id), [1, 2, 3, 4, 5]);
        expect((await log.debugLayout()).blocks, 4);
      },
    );

    test(
      'entriesAfter works across blocks, inside a block and in the tail',
      () async {
        final log = open();
        addTearDown(log.close);
        await log.appendAll(_walk('a', 10));
        await log.appendAll(_walk('a', 2, from: 10));

        expect(
          (await log.entriesAfter(0, limit: 100)).map((e) => e.id),
          [for (var i = 1; i <= 12; i++) i],
        );
        expect(
          (await log.entriesAfter(5, limit: 100)).map((e) => e.id),
          [for (var i = 6; i <= 12; i++) i],
        );
        expect(
          (await log.entriesAfter(4, limit: 3)).map((e) => e.id),
          [5, 6, 7],
        );
        expect(
          (await log.entriesAfter(10, limit: 100)).map((e) => e.id),
          [11, 12],
        );
        expect(await log.entriesAfter(12), isEmpty);
      },
    );

    test('lastEntryOfSession finds points in blocks and in the tail', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 9));
      await log.appendAll([_entry('b', 99)]);
      await log.append(_entry('a', 100));

      expect((await log.lastEntryOfSession('a', atOrBeforeId: 5))!.id, 5);
      expect((await log.lastEntryOfSession('a', atOrBeforeId: 9))!.id, 9);
      expect((await log.lastEntryOfSession('a', atOrBeforeId: 11))!.id, 11);
      expect((await log.lastEntryOfSession('b', atOrBeforeId: 11))!.id, 10);
      expect(await log.lastEntryOfSession('b', atOrBeforeId: 9), isNull);
      expect(await log.lastEntryOfSession('zzz', atOrBeforeId: 99), isNull);
    });

    test('entriesInBounds looks into blocks and the tail', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 10));
      await log.appendAll(_walk('a', 2, from: 10));

      final inside = await log.entriesInBounds(
        south: 50.0003,
        west: 18,
        north: 50.0010,
        east: 20,
      );

      expect(inside.map((e) => e.id), [for (var i = 4; i <= 11; i++) i]);
    });

    test('entriesInBounds stops at the limit and keeps the oldest', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 12));

      final some = await log.entriesInBounds(
        south: 0,
        west: 0,
        north: 90,
        east: 90,
        limit: 5,
      );

      expect(some.map((e) => e.id), [1, 2, 3, 4, 5]);
    });

    test('entriesBetween looks into blocks and the tail', () async {
      final log = open();
      addTearDown(log.close);
      await log.appendAll(_walk('a', 10));
      await log.appendAll(_walk('b', 3, from: 100));

      final found = await log.entriesBetween(3000, 101000);

      expect(
        found.map((e) => e.timestampMs),
        [for (var i = 3; i < 10; i++) i * 1000, 100000, 101000],
      );
    });

    test(
      'summaries and counts come from the sessions without reading points',
      () async {
        final log = open();
        addTearDown(log.close);
        await log.appendAll(_walk('a', 9));
        await log.appendAll(_walk('b', 2, from: 50));

        final sessions = await log.sessionSummaries();

        expect(sessions.map((s) => s.sessionId), ['a', 'b']);
        expect(sessions[0].pointCount, 9);
        expect(sessions[0].startMs, 0);
        expect(sessions[0].endMs, 8000);
        expect(sessions[1].pointCount, 2);
        expect(await log.count(), 11);
        expect(await log.lastId(), 11);
      },
    );
  });

  group('persistence', () {
    test('everything survives closing and opening again', () async {
      final first = open();
      await first.appendAll(_walk('a', 10));
      await first.appendAll(_walk('a', 2, from: 10));
      await first.close();

      final second = open();
      addTearDown(second.close);

      final all = await second.entriesAfter(0, limit: 100);
      expect(all.map((e) => e.id), [for (var i = 1; i <= 12; i++) i]);
      expect(await second.count(), 12);
    });

    test('the tail left by a crash is turned into blocks on start', () async {
      final first = open();
      await first.appendAll(_walk('a', 3));
      expect(await first.debugLayout(), (blocks: 0, tailRows: 3));
      await first.close();

      final second = open();
      addTearDown(second.close);
      await second.count();

      expect(await second.debugLayout(), (blocks: 1, tailRows: 0));
      expect((await second.entriesAfter(0)).length, 3);
    });

    test('new points continue the numbering after a restart', () async {
      final first = open();
      await first.appendAll(_walk('a', 6));
      await first.close();

      final second = open();
      addTearDown(second.close);
      final next = await second.append(_entry('a', 99999));

      expect(next.id, 7);
      expect((await second.entriesAfter(0, limit: 100)).length, 7);
    });

    test('a session continues across a restart', () async {
      final first = open();
      await first.appendAll(_walk('a', 6));
      await first.close();

      final second = open();
      addTearDown(second.close);
      await second.appendAll(_walk('a', 3, from: 6));

      final sessions = await second.sessionSummaries();
      expect(sessions.single.pointCount, 9);
      expect(sessions.single.endMs, 8000);
    });

    test('ids keep growing after clear and a restart', () async {
      final first = open();
      await first.appendAll(_walk('a', 6));
      await first.clear();
      await first.close();

      final second = open();
      addTearDown(second.close);
      final next = await second.append(_entry('b', 1));

      expect(next.id, 7);
      expect(await second.count(), 1);
    });
  });

  group('concurrent access', () {
    test('a read during the first append keeps point numbers unique', () async {
      final seed = open();
      await seed.appendAll(_walk('a', 6));
      await seed.close();

      for (var delay = 0; delay < 12; delay++) {
        final log = open();
        try {
          final appended = log.append(_entry('b', 1000 * (100 + delay)));
          for (var i = 0; i < delay; i++) {
            await Future<void>.delayed(Duration.zero);
          }
          await Future.wait([appended, log.sessionSummaries()]);

          final next = await log.append(_entry('b', 1000 * (200 + delay)));

          expect(next.id, (await appended).id! + 1, reason: 'delay $delay');
        } finally {
          await log.close();
        }
      }
    });

    test('closing waits for a read in progress', () async {
      final log = open();
      await log.appendAll(_walk('a', 10));

      final reading = log.entriesAfter(0);
      await log.close();

      expect(await reading, hasLength(10));
    });
  });

  group('size', () {
    test('a journey takes only a few bytes per point on disk', () async {
      final journey = ExplorerRouteGenerator.generate(
        start: const LatLng(50.0614, 19.9383),
        totalKm: 200,
      );
      final log = SqfliteTrackLogStorage(path: path);
      addTearDown(log.close);

      await log.appendAll(journey);
      await log.compact();

      final bytes = await log.fileBytes();
      expect(bytes / journey.length, lessThan(12));
    });

    test('adding points one by one ends up as compact as one batch', () async {
      final journey = ExplorerRouteGenerator.generate(
        start: const LatLng(50.0614, 19.9383),
        totalKm: 10,
      );
      final batch = SqfliteTrackLogStorage(path: '${dir.path}/batch.db');
      final single = SqfliteTrackLogStorage(path: '${dir.path}/single.db');
      addTearDown(batch.close);
      addTearDown(single.close);

      await batch.appendAll(journey);
      for (final entry in journey) {
        await single.append(entry);
      }
      await batch.compact();
      await single.compact();

      expect(await single.count(), journey.length);
      // The pages that held the tail stay in the file for reuse, a fixed
      // cost that does not grow with the number of points.
      final extra = (await single.fileBytes()) - (await batch.fileBytes());
      expect(extra, lessThan(48 * 1024));
    });
  });
}
