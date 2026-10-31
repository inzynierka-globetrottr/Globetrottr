import 'package:globetrottr_front/features/map/data/track_log/track_log_blocks.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_state.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:sqflite/sqflite.dart';

/// Reads of the track log. Blocks hold the older points and the tail the
/// newest ones, so every query looks at both.
class TrackLogQueries {
  const TrackLogQueries(this.db, this.state);

  final DatabaseExecutor db;
  final TrackLogState state;

  /// Entries with an id greater than [afterId], oldest first.
  Future<List<TrackLogEntry>> entriesAfter(int afterId, int limit) async {
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
        for (final entry in decodeBlockRow(row, state)) {
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
    return [...result, for (final row in tail) tailRowEntry(row, state)];
  }

  /// Entries recorded between [fromMs] and [toMs] (inclusive), by time.
  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs) async {
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
        for (final e in decodeBlockRow(row, state))
          if (e.timestampMs >= fromMs && e.timestampMs <= toMs) e,
      for (final row in tail) tailRowEntry(row, state),
    ]..sort((a, b) {
      final byTime = a.timestampMs.compareTo(b.timestampMs);
      return byTime != 0 ? byTime : a.id!.compareTo(b.id!);
    });
  }

  /// Entries inside the box (borders included), oldest first.
  Future<List<TrackLogEntry>> entriesInBounds(
    double south,
    double west,
    double north,
    double east,
    int limit,
  ) async {
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
      for (final entry in decodeBlockRow(row, state)) {
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
    return [...result, for (final row in tail) tailRowEntry(row, state)];
  }

  /// Latest entry of [sessionId] whose id is at most [atOrBeforeId].
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId,
    int atOrBeforeId,
  ) async {
    final session = state.sessions[sessionId];
    if (session == null) return null;

    final tail = await db.query(
      'track_tail',
      where: 'session_ref = ? AND id <= ?',
      whereArgs: [session.ref, atOrBeforeId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (tail.isNotEmpty) return tailRowEntry(tail.single, state);

    final blocks = await db.query(
      'track_blocks',
      where: 'session_ref = ? AND first_id <= ?',
      whereArgs: [session.ref, atOrBeforeId],
      orderBy: 'first_id DESC',
      limit: 1,
    );
    if (blocks.isEmpty) return null;
    final inBlock = decodeBlockRow(
      blocks.single,
      state,
    ).where((e) => e.id! <= atOrBeforeId).toList();
    return inBlock.isEmpty ? null : inBlock.last;
  }
}
