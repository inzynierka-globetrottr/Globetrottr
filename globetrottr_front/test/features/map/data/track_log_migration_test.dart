import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/sqflite_track_log_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('a version 1 database is upgraded without losing points', () async {
    final dir = await Directory.systemTemp.createTemp('tracks_migration');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/tracks.db';

    final old = await openDatabase(
      path,
      version: 1,
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
    final found = await storage.entriesInBounds(
      south: 49,
      west: 18,
      north: 51,
      east: 20,
    );
    await storage.close();

    expect(found.single.sessionId, 'old');
    final check = await openDatabase(path);
    final indexes = await check.rawQuery('PRAGMA index_list(track_points)');
    await check.close();
    expect(
      indexes.map((row) => row['name']),
      contains('track_points_position'),
    );
  });

  test('a new database has the position index too', () async {
    final storage = SqfliteTrackLogStorage(path: inMemoryDatabasePath);
    addTearDown(storage.close);

    expect(await storage.count(), 0);
    expect(
      await storage.entriesInBounds(south: 0, west: 0, north: 1, east: 1),
      isEmpty,
    );
  });
}
