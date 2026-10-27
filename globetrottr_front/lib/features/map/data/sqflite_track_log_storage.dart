import 'package:globetrottr_front/core/storage/database_files.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Permanent route history in its own file, separate from the fog cache and
/// from `pending_points` (which a sync empties).
class SqfliteTrackLogStorage implements TrackLogStorage {
  SqfliteTrackLogStorage({this.path});

  /// Database location; null uses `tracks.db` in the default folder.
  final String? path;

  Database? _database;

  Future<Database> get _db async => _database ??= await _open();

  Future<String> _location() async =>
      path ?? join(await getDatabasesPath(), 'tracks.db');

  @override
  Future<int> fileBytes() async => databaseFileBytes(await _location());

  Future<Database> _open() async {
    final location = await _location();
    return openDatabase(
      location,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createPositionIndex(db);
      },
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
        await db.execute(
          'CREATE INDEX track_points_session ON track_points (session_id, id)',
        );
        await _createPositionIndex(db);
      },
    );
  }

  /// Lets the "points inside this map view" query skip the rest of the log.
  Future<void> _createPositionIndex(Database db) {
    return db.execute(
      'CREATE INDEX IF NOT EXISTS track_points_position '
      'ON track_points (lat, lng)',
    );
  }

  Map<String, Object?> _toRow(TrackLogEntry e) => {
    'session_id': e.sessionId,
    'ts': e.timestampMs,
    'lat': e.latitude,
    'lng': e.longitude,
    'accuracy': e.accuracy,
    'speed': e.speed,
  };

  TrackLogEntry _fromRow(Map<String, Object?> row) {
    return TrackLogEntry(
      id: row['id']! as int,
      sessionId: row['session_id']! as String,
      timestampMs: row['ts']! as int,
      latitude: (row['lat']! as num).toDouble(),
      longitude: (row['lng']! as num).toDouble(),
      accuracy: (row['accuracy'] as num?)?.toDouble(),
      speed: (row['speed'] as num?)?.toDouble(),
    );
  }

  @override
  Future<TrackLogEntry> append(TrackLogEntry entry) async {
    final db = await _db;
    final id = await db.insert('track_points', _toRow(entry));
    return entry.withId(id);
  }

  @override
  Future<List<TrackLogEntry>> appendAll(List<TrackLogEntry> entries) async {
    if (entries.isEmpty) return const [];
    final db = await _db;
    final ids = await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('track_points', _toRow(entry));
      }
      return batch.commit();
    });
    return [
      for (var i = 0; i < entries.length; i++)
        entries[i].withId(ids[i]! as int),
    ];
  }

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'track_points',
      where: 'id > ?',
      whereArgs: [afterId],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs) async {
    final db = await _db;
    final rows = await db.query(
      'track_points',
      where: 'ts >= ? AND ts <= ?',
      whereArgs: [fromMs, toMs],
      orderBy: 'ts ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'track_points',
      where: 'session_id = ? AND id <= ?',
      whereArgs: [sessionId, atOrBeforeId],
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<List<TrackSessionSummary>> sessionSummaries() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT session_id, MIN(ts) AS start_ts, MAX(ts) AS end_ts, '
      'COUNT(*) AS points FROM track_points '
      'GROUP BY session_id ORDER BY start_ts ASC',
    );
    return [
      for (final row in rows)
        TrackSessionSummary(
          sessionId: row['session_id']! as String,
          startMs: row['start_ts']! as int,
          endMs: row['end_ts']! as int,
          pointCount: row['points']! as int,
        ),
    ];
  }

  @override
  Future<int> count() async {
    final db = await _db;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM track_points'),
        ) ??
        0;
  }

  @override
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'track_points',
      where: 'lat >= ? AND lat <= ? AND lng >= ? AND lng <= ?',
      whereArgs: [south, north, west, east],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> lastId() async {
    final db = await _db;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(id) FROM track_points'),
        ) ??
        0;
  }

  @override
  Future<void> clear() async {
    final db = await _db;
    await db.delete('track_points');
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
