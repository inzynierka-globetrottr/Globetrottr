import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/sqflite_track_log_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Future<List<String>> tables(String path) async {
    final db = await openDatabase(path);
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    await db.close();
    return [for (final row in rows) row['name']! as String];
  }

  test('a log from an older version is replaced by an empty new one', () async {
    final dir = await Directory.systemTemp.createTemp('tracks_migration');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/tracks.db';

    final old = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE track_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            ts INTEGER NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            accuracy REAL,
            speed REAL
          )
        ''');
        await db.execute('CREATE INDEX track_points_ts ON track_points (ts)');
        await db.insert('track_points', {
          'session_id': 'old',
          'ts': 1,
          'lat': 50.0,
          'lng': 19.0,
        });
      },
    );
    await old.close();

    final storage = SqfliteTrackLogStorage(path: path);
    expect(await storage.count(), 0);
    final appended = await storage.append(
      const _Fix('new', 5, 51, 20).toEntry(),
    );
    await storage.close();

    expect(appended.id, 1);
    final names = await tables(path);
    expect(names, isNot(contains('track_points')));
    expect(
      names,
      containsAll(['track_sessions', 'track_blocks', 'track_tail']),
    );
  });

  test('a new database starts with the new tables', () async {
    final storage = SqfliteTrackLogStorage(path: inMemoryDatabasePath);
    addTearDown(storage.close);

    expect(await storage.count(), 0);
    expect(
      await storage.entriesInBounds(south: 0, west: 0, north: 1, east: 1),
      isEmpty,
    );
    expect(await storage.sessionSummaries(), isEmpty);
  });

  test('opening the new format again does not touch it', () async {
    final dir = await Directory.systemTemp.createTemp('tracks_reopen');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/tracks.db';
    final first = SqfliteTrackLogStorage(path: path);
    await first.append(const _Fix('a', 1, 50, 19).toEntry());
    await first.close();

    final second = SqfliteTrackLogStorage(path: path);
    addTearDown(second.close);

    expect(await second.count(), 1);
  });
}

class _Fix {
  const _Fix(this.session, this.ts, this.lat, this.lng);

  final String session;
  final int ts;
  final double lat;
  final double lng;

  TrackLogEntry toEntry() => TrackLogEntry(
    sessionId: session,
    timestampMs: ts,
    latitude: lat,
    longitude: lng,
  );
}
