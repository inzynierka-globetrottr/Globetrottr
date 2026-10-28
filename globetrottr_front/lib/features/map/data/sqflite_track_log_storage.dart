import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:globetrottr_front/core/storage/database_files.dart';
import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class _Session {
  const _Session({
    required this.ref,
    required this.sessionId,
    required this.firstId,
    required this.lastId,
    required this.startTs,
    required this.endTs,
    required this.count,
  });

  factory _Session.fromRow(Map<String, Object?> row) => _Session(
    ref: row['ref']! as int,
    sessionId: row['session_id']! as String,
    firstId: row['first_id']! as int,
    lastId: row['last_id']! as int,
    startTs: row['start_ts']! as int,
    endTs: row['end_ts']! as int,
    count: row['point_count']! as int,
  );

  final int ref;
  final String sessionId;
  final int firstId;
  final int lastId;
  final int startTs;
  final int endTs;
  final int count;

  _Session add(TrackLogEntry entry) => _Session(
    ref: ref,
    sessionId: sessionId,
    firstId: firstId,
    lastId: entry.id!,
    startTs: math.min(startTs, entry.timestampMs),
    endTs: math.max(endTs, entry.timestampMs),
    count: count + 1,
  );

  Map<String, Object?> toRow() => {
    'session_id': sessionId,
    'first_id': firstId,
    'last_id': lastId,
    'start_ts': startTs,
    'end_ts': endTs,
    'point_count': count,
  };
}

class _State {
  _State(this.sessions, this.nextId, this.tailCount)
    : names = {for (final s in sessions.values) s.ref: s.sessionId};

  final Map<String, _Session> sessions;
  final Map<int, String> names;
  int nextId;
  int tailCount;
}

/// Permanent route history in its own file, separate from the fog cache and
/// from `pending_points` (which a sync empties).
///
/// Points are kept in three places:
/// - `track_sessions`: one row per session with its id range, time span and
///   number of points, so a list of trips never has to read any point;
/// - `track_blocks`: finished runs of up to [blockSize] points of one
///   session, packed by `TrackBlockCodec` (about 5 bytes per point);
/// - `track_tail`: the newest points as plain rows, so a point that has just
///   been recorded is stored at once. When the tail holds [blockSize] points,
///   when recording stops and when the database is opened, it is packed
///   into blocks.
///
/// Every point has a number that only grows, even across [clear], so the
/// fog can remember how far it has drawn.
class SqfliteTrackLogStorage implements TrackLogStorage {
  SqfliteTrackLogStorage({this.path, this.blockSize = 500});

  /// Database location; null uses `tracks.db` in the default folder.
  final String? path;
  final int blockSize;

  static const int _schemaVersion = 3;

  Database? _database;
  _State? _state;
  Future<void> _tail = Future.value();

  Future<Database> get _db async => _database ??= await _open();

  Future<String> _location() async =>
      path ?? join(await getDatabasesPath(), 'tracks.db');

  @override
  Future<int> fileBytes() async => databaseFileBytes(await _location());

  Future<Database> _open() async {
    final location = await _location();
    return openDatabase(
      location,
      version: _schemaVersion,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // The earlier formats only ever held test data and are not kept.
        await db.execute('DROP TABLE IF EXISTS track_points');
        await _createTables(db);
      },
      onOpen: (db) => db.transaction(_flushTail),
    );
  }

  Future<void> _createTables(Database db) async {
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

  Future<_State> _loadState(Database db) async {
    final cached = _state;
    if (cached != null) return cached;
    final sessions = {
      for (final row in await db.query('track_sessions'))
        row['session_id']! as String: _Session.fromRow(row),
    };
    final newest = sessions.values.fold<int>(
      0,
      (m, s) => math.max(m, s.lastId),
    );
    final saved = await db.query('track_meta', where: "key = 'next_id'");
    final remembered = saved.isEmpty ? 1 : saved.single['value']! as int;
    final tailCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM track_tail'),
        ) ??
        0;
    return _state = _State(
      sessions,
      math.max(newest + 1, remembered),
      tailCount,
    );
  }

  /// Runs every operation, reads included, one after another. Several fixes
  /// can arrive while an earlier one is still being stored, and they must not
  /// share a point number; a read must not see half of a write nor load the
  /// cached state while a write is changing it.
  Future<T> _serial<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await task());
      } on Object catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  @override
  Future<TrackLogEntry> append(TrackLogEntry entry) async {
    return (await appendAll([entry])).single;
  }

  @override
  Future<List<TrackLogEntry>> appendAll(List<TrackLogEntry> entries) {
    if (entries.isEmpty) return Future.value(const []);
    return _serial(() => _appendAll(entries));
  }

  Future<List<TrackLogEntry>> _appendAll(List<TrackLogEntry> entries) async {
    final db = await _db;
    final state = await _loadState(db);

    // Rounds the values first, so a bad one stops the whole batch before
    // anything is written.
    var id = state.nextId;
    final stored = [
      for (final entry in entries) TrackBlockCodec.quantize(entry).withId(id++),
    ];

    final updated = <String, _Session>{};
    var tailCount = state.tailCount;
    await db.transaction((txn) async {
      for (final entry in stored) {
        final known =
            updated[entry.sessionId] ?? state.sessions[entry.sessionId];
        if (known == null) {
          final ref = await txn.insert('track_sessions', {
            'session_id': entry.sessionId,
            'first_id': entry.id,
            'last_id': entry.id,
            'start_ts': entry.timestampMs,
            'end_ts': entry.timestampMs,
            'point_count': 1,
          });
          updated[entry.sessionId] = _Session(
            ref: ref,
            sessionId: entry.sessionId,
            firstId: entry.id!,
            lastId: entry.id!,
            startTs: entry.timestampMs,
            endTs: entry.timestampMs,
            count: 1,
          );
        } else {
          updated[entry.sessionId] = known.add(entry);
        }
      }
      for (final session in updated.values) {
        await txn.update(
          'track_sessions',
          session.toRow(),
          where: 'ref = ?',
          whereArgs: [session.ref],
        );
      }

      int refOf(TrackLogEntry e) => updated[e.sessionId]!.ref;
      if (stored.length >= blockSize) {
        if (tailCount > 0) await _flushTail(txn);
        tailCount = 0;
        await _writeBlocks(txn, stored, refOf);
      } else {
        final batch = txn.batch();
        for (final e in stored) {
          batch.insert('track_tail', {
            'id': e.id,
            'session_ref': refOf(e),
            'ts': e.timestampMs,
            'lat': e.latitude,
            'lng': e.longitude,
            'accuracy': e.accuracy,
            'speed': e.speed,
          });
        }
        await batch.commit(noResult: true);
        tailCount += stored.length;
        if (tailCount >= blockSize) {
          await _flushTail(txn);
          tailCount = 0;
        }
      }
    });

    state.sessions.addAll(updated);
    for (final session in updated.values) {
      state.names[session.ref] = session.sessionId;
    }
    state.nextId = id;
    state.tailCount = tailCount;
    return stored;
  }

  Future<void> _writeBlocks(
    DatabaseExecutor txn,
    List<TrackLogEntry> entries,
    int Function(TrackLogEntry) refOf,
  ) async {
    var start = 0;
    while (start < entries.length) {
      final ref = refOf(entries[start]);
      var end = start + 1;
      while (end < entries.length &&
          end - start < blockSize &&
          refOf(entries[end]) == ref) {
        end++;
      }
      await _writeBlock(txn, ref, entries.sublist(start, end));
      start = end;
    }
  }

  Future<void> _writeBlock(
    DatabaseExecutor txn,
    int ref,
    List<TrackLogEntry> entries,
  ) async {
    final bounds = TrackBlockCodec.boundsOf(entries);
    final times = TrackBlockCodec.timeRangeOf(entries);
    await txn.insert('track_blocks', {
      'session_ref': ref,
      'first_id': entries.first.id,
      'point_count': entries.length,
      'min_ts': times.start,
      'max_ts': times.end,
      'lat_min': bounds.south,
      'lat_max': bounds.north,
      'lng_min': bounds.west,
      'lng_max': bounds.east,
      'data': TrackBlockCodec.encode(entries),
    });
  }

  /// Packs every point of the tail into blocks and empties the tail.
  Future<void> _flushTail(DatabaseExecutor txn) async {
    final rows = await txn.query('track_tail', orderBy: 'id');
    if (rows.isEmpty) return;

    var run = <TrackLogEntry>[];
    var runRef = -1;
    Future<void> finishRun() async {
      if (run.isEmpty) return;
      await _writeBlock(txn, runRef, run);
      run = [];
    }

    for (final row in rows) {
      final ref = row['session_ref']! as int;
      final id = row['id']! as int;
      final continues =
          run.isNotEmpty &&
          ref == runRef &&
          id == run.last.id! + 1 &&
          run.length < blockSize;
      if (!continues) await finishRun();
      runRef = ref;
      run.add(
        TrackLogEntry(
          id: id,
          sessionId: '',
          timestampMs: row['ts']! as int,
          latitude: (row['lat']! as num).toDouble(),
          longitude: (row['lng']! as num).toDouble(),
          accuracy: (row['accuracy'] as num?)?.toDouble(),
          speed: (row['speed'] as num?)?.toDouble(),
        ),
      );
    }
    await finishRun();
    await txn.delete('track_tail');
  }

  @override
  Future<void> compact() {
    return _serial(() async {
      final db = await _db;
      final state = await _loadState(db);
      if (state.tailCount == 0) return;
      await db.transaction(_flushTail);
      state.tailCount = 0;
    });
  }

  List<TrackLogEntry> _decodeBlock(Map<String, Object?> row, _State state) {
    final data = row['data']! as List<int>;
    return TrackBlockCodec.decode(
      data is Uint8List ? data : Uint8List.fromList(data),
      sessionId: state.names[row['session_ref']! as int]!,
      firstId: row['first_id']! as int,
    );
  }

  TrackLogEntry _tailEntry(Map<String, Object?> row, _State state) {
    return TrackLogEntry(
      id: row['id']! as int,
      sessionId: state.names[row['session_ref']! as int]!,
      timestampMs: row['ts']! as int,
      latitude: (row['lat']! as num).toDouble(),
      longitude: (row['lng']! as num).toDouble(),
      accuracy: (row['accuracy'] as num?)?.toDouble(),
      speed: (row['speed'] as num?)?.toDouble(),
    );
  }

  @override
  Future<List<TrackLogEntry>> entriesAfter(int afterId, {int limit = 5000}) {
    return _serial(() => _entriesAfter(afterId, limit));
  }

  Future<List<TrackLogEntry>> _entriesAfter(int afterId, int limit) async {
    final db = await _db;
    final state = await _loadState(db);
    final result = <TrackLogEntry>[];

    final start = await db.rawQuery(
      'SELECT first_id FROM track_blocks WHERE first_id <= ? '
      'ORDER BY first_id DESC LIMIT 1',
      [afterId + 1],
    );
    var from = start.isEmpty ? 0 : start.first['first_id']! as int;
    while (result.length < limit) {
      final rows = await db.query(
        'track_blocks',
        where: 'first_id >= ?',
        whereArgs: [from],
        orderBy: 'first_id',
        limit: 8,
      );
      if (rows.isEmpty) break;
      for (final row in rows) {
        for (final entry in _decodeBlock(row, state)) {
          if (entry.id! <= afterId) continue;
          result.add(entry);
          if (result.length >= limit) return result;
        }
      }
      from = (rows.last['first_id']! as int) + 1;
    }

    final tail = await db.query(
      'track_tail',
      where: 'id > ?',
      whereArgs: [afterId],
      orderBy: 'id',
      limit: limit - result.length,
    );
    return [...result, for (final row in tail) _tailEntry(row, state)];
  }

  @override
  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs) {
    return _serial(() => _entriesBetween(fromMs, toMs));
  }

  Future<List<TrackLogEntry>> _entriesBetween(int fromMs, int toMs) async {
    final db = await _db;
    final state = await _loadState(db);
    final blocks = await db.query(
      'track_blocks',
      where: 'max_ts >= ? AND min_ts <= ?',
      whereArgs: [fromMs, toMs],
    );
    final tail = await db.query(
      'track_tail',
      where: 'ts >= ? AND ts <= ?',
      whereArgs: [fromMs, toMs],
    );
    return [
      for (final row in blocks)
        for (final e in _decodeBlock(row, state))
          if (e.timestampMs >= fromMs && e.timestampMs <= toMs) e,
      for (final row in tail) _tailEntry(row, state),
    ]..sort((a, b) {
      final byTime = a.timestampMs.compareTo(b.timestampMs);
      return byTime != 0 ? byTime : a.id!.compareTo(b.id!);
    });
  }

  @override
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  }) {
    return _serial(() => _entriesInBounds(south, west, north, east, limit));
  }

  Future<List<TrackLogEntry>> _entriesInBounds(
    double south,
    double west,
    double north,
    double east,
    int limit,
  ) async {
    final db = await _db;
    final state = await _loadState(db);
    bool inside(TrackLogEntry e) =>
        e.latitude >= south &&
        e.latitude <= north &&
        e.longitude >= west &&
        e.longitude <= east;

    final blocks = await db.query(
      'track_blocks',
      where: 'lat_max >= ? AND lat_min <= ? AND lng_max >= ? AND lng_min <= ?',
      whereArgs: [south, north, west, east],
      orderBy: 'first_id',
    );
    final result = <TrackLogEntry>[];
    for (final row in blocks) {
      for (final entry in _decodeBlock(row, state)) {
        if (!inside(entry)) continue;
        result.add(entry);
        if (result.length >= limit) return result;
      }
    }
    final tail = await db.query(
      'track_tail',
      where: 'lat >= ? AND lat <= ? AND lng >= ? AND lng <= ?',
      whereArgs: [south, north, west, east],
      orderBy: 'id',
      limit: limit - result.length,
    );
    return [...result, for (final row in tail) _tailEntry(row, state)];
  }

  @override
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  }) {
    return _serial(() => _lastEntryOfSession(sessionId, atOrBeforeId));
  }

  Future<TrackLogEntry?> _lastEntryOfSession(
    String sessionId,
    int atOrBeforeId,
  ) async {
    final db = await _db;
    final state = await _loadState(db);
    final session = state.sessions[sessionId];
    if (session == null) return null;

    final tail = await db.query(
      'track_tail',
      where: 'session_ref = ? AND id <= ?',
      whereArgs: [session.ref, atOrBeforeId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (tail.isNotEmpty) return _tailEntry(tail.single, state);

    final blocks = await db.query(
      'track_blocks',
      where: 'session_ref = ? AND first_id <= ?',
      whereArgs: [session.ref, atOrBeforeId],
      orderBy: 'first_id DESC',
      limit: 1,
    );
    if (blocks.isEmpty) return null;
    final inBlock = _decodeBlock(
      blocks.single,
      state,
    ).where((e) => e.id! <= atOrBeforeId).toList();
    return inBlock.isEmpty ? null : inBlock.last;
  }

  @override
  Future<List<TrackSessionSummary>> sessionSummaries() {
    return _serial(() async {
      final state = await _loadState(await _db);
      final sessions = state.sessions.values.toList()
        ..sort((a, b) {
          final byStart = a.startTs.compareTo(b.startTs);
          return byStart != 0 ? byStart : a.firstId.compareTo(b.firstId);
        });
      return [
        for (final s in sessions)
          TrackSessionSummary(
            sessionId: s.sessionId,
            startMs: s.startTs,
            endMs: s.endTs,
            pointCount: s.count,
          ),
      ];
    });
  }

  @override
  Future<int> count() {
    return _serial(() async {
      final state = await _loadState(await _db);
      return state.sessions.values.fold<int>(0, (sum, s) => sum + s.count);
    });
  }

  @override
  Future<int> lastId() {
    return _serial(() async {
      final state = await _loadState(await _db);
      return state.sessions.values.fold<int>(
        0,
        (m, s) => math.max(m, s.lastId),
      );
    });
  }

  @override
  Future<void> clear() {
    return _serial(() async {
      final db = await _db;
      final state = await _loadState(db);
      await db.transaction((txn) async {
        await txn.delete('track_tail');
        await txn.delete('track_blocks');
        await txn.delete('track_sessions');
        await txn.insert('track_meta', {
          'key': 'next_id',
          'value': state.nextId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      state.sessions.clear();
      state.names.clear();
      state.tailCount = 0;
    });
  }

  /// How the points are stored right now. Only for tests.
  @visibleForTesting
  Future<({int blocks, int tailRows})> debugLayout() {
    return _serial(() async {
      final db = await _db;
      await _loadState(db);
      return (
        blocks:
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM track_blocks'),
            ) ??
            0,
        tailRows:
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM track_tail'),
            ) ??
            0,
      );
    });
  }

  @override
  Future<void> close() {
    return _serial(() async {
      await _database?.close();
      _database = null;
      _state = null;
    });
  }
}
