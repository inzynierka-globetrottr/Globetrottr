import 'package:sqflite/sqflite.dart';

const int trackLogSchemaVersion = 3;

/// Replaces an older format; those only ever held test data and are not
/// kept.
Future<void> upgradeTrackLogTables(Database db) async {
  await db.execute('DROP TABLE IF EXISTS track_points');
  await createTrackLogTables(db);
}

Future<void> createTrackLogTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS track_sessions (
      ref INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT NOT NULL UNIQUE,
      first_id INTEGER NOT NULL,
      last_id INTEGER NOT NULL,
      start_ts INTEGER NOT NULL,
      end_ts INTEGER NOT NULL,
      point_count INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS track_blocks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_ref INTEGER NOT NULL,
      first_id INTEGER NOT NULL,
      point_count INTEGER NOT NULL,
      min_ts INTEGER NOT NULL,
      max_ts INTEGER NOT NULL,
      lat_min REAL NOT NULL,
      lat_max REAL NOT NULL,
      lng_min REAL NOT NULL,
      lng_max REAL NOT NULL,
      data BLOB NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS track_blocks_first ON track_blocks (first_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS track_blocks_session '
    'ON track_blocks (session_ref, first_id)',
  );
  await db.execute('''
    CREATE TABLE IF NOT EXISTS track_tail (
      id INTEGER PRIMARY KEY,
      session_ref INTEGER NOT NULL,
      ts INTEGER NOT NULL,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      accuracy REAL,
      speed REAL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS track_meta (
      key TEXT PRIMARY KEY,
      value INTEGER NOT NULL
    )
  ''');
}
