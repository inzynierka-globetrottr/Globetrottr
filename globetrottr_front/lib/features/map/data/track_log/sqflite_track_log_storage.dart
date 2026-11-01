import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/core/storage/database_files.dart';
import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_blocks.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_queries.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_schema.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_state.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
  SqfliteTrackLogStorage({this.path, this.blockSize = 500})
    : _blocks = TrackLogBlockWriter(blockSize);

  /// Database location; null uses `tracks.db` in the default folder.
  final String? path;
  final int blockSize;
  final TrackLogBlockWriter _blocks;

  Database? _database;
  TrackLogState? _state;

  /// Runs every operation, reads included, one after another. Several fixes
  /// can arrive while an earlier one is still being stored, and they must not
  /// share a point number; a read must not see half of a write nor load the
  /// cached state while a write is changing it.
  final SerialQueue _queue = SerialQueue();

  Future<Database> get _db async => _database ??= await _open();

  Future<String> _location() async =>
      path ?? join(await getDatabasesPath(), 'tracks.db');

  @override
  Future<int> fileBytes() async => databaseFileBytes(await _location());

  Future<Database> _open() async {
    final location = await _location();
    return openDatabase(
      location,
      version: trackLogSchemaVersion,
      onCreate: (db, version) => createTrackLogTables(db),
      onUpgrade: (db, oldVersion, newVersion) => upgradeTrackLogTables(db),
      onOpen: (db) => db.transaction(_blocks.flushTail),
    );
  }

  Future<TrackLogState> _loadState(Database db) async {
    return _state ??= await TrackLogState.read(db);
  }

  /// Runs [read] in the queue with the open database and its state.
  Future<T> _read<T>(Future<T> Function(TrackLogQueries queries) read) {
    return _queue.run(() async {
      final db = await _db;
      return read(TrackLogQueries(db, await _loadState(db)));
    });
  }

  /// Runs [read] in the queue with the cached state of the database.
  Future<T> _readState<T>(T Function(TrackLogState state) read) {
    return _read((queries) async => read(queries.state));
  }

  @override
  Future<TrackLogEntry> append(TrackLogEntry entry) async {
    return (await appendAll([entry])).single;
  }

  @override
  Future<List<TrackLogEntry>> appendAll(List<TrackLogEntry> entries) {
    if (entries.isEmpty) return Future.value(const []);
    return _queue.run(() => _appendAll(entries));
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

    final updated = <String, TrackLogSession>{};
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
          updated[entry.sessionId] = TrackLogSession(
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
        if (tailCount > 0) await _blocks.flushTail(txn);
        tailCount = 0;
        await _blocks.writeBlocks(txn, stored, refOf);
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
          await _blocks.flushTail(txn);
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

  @override
  Future<void> compact() {
    return _queue.run(() async {
      final db = await _db;
      final state = await _loadState(db);
      if (state.tailCount == 0) return;
      await db.transaction(_blocks.flushTail);
      state.tailCount = 0;
    });
  }

  @override
  Future<List<TrackLogEntry>> entriesAfter(int afterId, {int limit = 5000}) {
    return _read((queries) => queries.entriesAfter(afterId, limit));
  }

  @override
  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs) {
    return _read((queries) => queries.entriesBetween(fromMs, toMs));
  }

  @override
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  }) {
    return _read(
      (queries) => queries.entriesInBounds(south, west, north, east, limit),
    );
  }

  @override
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  }) {
    return _read(
      (queries) => queries.lastEntryOfSession(sessionId, atOrBeforeId),
    );
  }

  @override
  Future<List<TrackSessionSummary>> sessionSummaries() {
    return _readState((state) => state.summaries);
  }

  @override
  Future<int> count() => _readState((state) => state.pointCount);

  @override
  Future<int> lastId() => _readState((state) => state.newestId);

  @override
  Future<void> clear() {
    return _queue.run(() async {
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
    return _queue.run(() async {
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
    return _queue.run(() async {
      await _database?.close();
      _database = null;
      _state = null;
    });
  }
}
