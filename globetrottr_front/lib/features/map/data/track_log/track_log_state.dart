import 'dart:math' as math;

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:sqflite/sqflite.dart';

/// One row of `track_sessions`.
class TrackLogSession {
  const TrackLogSession({
    required this.ref,
    required this.sessionId,
    required this.firstId,
    required this.lastId,
    required this.startTs,
    required this.endTs,
    required this.count,
  });

  factory TrackLogSession.fromRow(Map<String, Object?> row) => TrackLogSession(
    ref: row['ref']! as int,
    sessionId: row['session_id']! as String,
    firstId: row['first_id']! as int,
    lastId: row['last_id']! as int,
    startTs: row['start_ts']! as int,
    endTs: row['end_ts']! as int,
    count: row['point_count']! as int,
  );

  /// Row id, used by blocks and tail rows to point at the session.
  final int ref;
  final String sessionId;
  final int firstId;
  final int lastId;
  final int startTs;
  final int endTs;
  final int count;

  TrackLogSession add(TrackLogEntry entry) => TrackLogSession(
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

/// What the storage keeps in memory about the database, so most writes and
/// summaries need no extra query.
class TrackLogState {
  TrackLogState(this.sessions, this.nextId, this.tailCount)
    : names = {for (final s in sessions.values) s.ref: s.sessionId};

  /// Sessions by their id.
  final Map<String, TrackLogSession> sessions;

  /// Session ids by [TrackLogSession.ref].
  final Map<int, String> names;

  /// Number the next stored point gets.
  int nextId;

  /// Points waiting in `track_tail`.
  int tailCount;

  int get pointCount => sessions.values.fold(0, (sum, s) => sum + s.count);

  /// Id of the newest stored point, or 0 when there is none.
  int get newestId => sessions.values.fold(0, (m, s) => math.max(m, s.lastId));

  /// Every session, the oldest first.
  List<TrackSessionSummary> get summaries {
    final ordered = sessions.values.toList()
      ..sort((a, b) {
        final byStart = a.startTs.compareTo(b.startTs);
        return byStart != 0 ? byStart : a.firstId.compareTo(b.firstId);
      });
    return [
      for (final s in ordered)
        TrackSessionSummary(
          sessionId: s.sessionId,
          startMs: s.startTs,
          endMs: s.endTs,
          pointCount: s.count,
        ),
    ];
  }

  static Future<TrackLogState> read(DatabaseExecutor db) async {
    final sessions = {
      for (final row in await db.query('track_sessions'))
        row['session_id']! as String: TrackLogSession.fromRow(row),
    };
    final saved = await db.query('track_meta', where: "key = 'next_id'");
    final remembered = saved.isEmpty ? 1 : saved.single['value']! as int;
    final tailCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM track_tail'),
        ) ??
        0;
    final state = TrackLogState(sessions, remembered, tailCount);
    state.nextId = math.max(state.newestId + 1, remembered);
    return state;
  }
}
