import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
import 'package:globetrottr_front/features/map/data/track_log/track_log_state.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:sqflite/sqflite.dart';

/// Writes points into `track_blocks` (packed runs of one session) and moves
/// the plain rows of `track_tail` into blocks.
class TrackLogBlockWriter {
  const TrackLogBlockWriter(this.blockSize);

  /// Most points in one block.
  final int blockSize;

  /// Writes consecutive [entries] as blocks, starting a new block whenever
  /// the session changes or a block is full.
  Future<void> writeBlocks(
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

  /// Packs every point of the tail into blocks and empties the tail.
  Future<void> flushTail(DatabaseExecutor txn) async {
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
      run.add(_tailRowEntry(row, sessionId: ''));
    }
    await finishRun();
    await txn.delete('track_tail');
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
}

/// The points of a `track_blocks` row. A damaged block is skipped and
/// logged, so it never stops the rest of the history from being read.
List<TrackLogEntry> decodeBlockRow(
  Map<String, Object?> row,
  TrackLogState state,
) {
  final firstId = row['first_id']! as int;
  final sessionId = state.names[row['session_ref']! as int];
  if (sessionId == null) {
    debugPrint('Skipping track block $firstId: its session is missing');
    return const [];
  }
  final data = row['data']! as List<int>;
  try {
    return TrackBlockCodec.decode(
      data is Uint8List ? data : Uint8List.fromList(data),
      sessionId: sessionId,
      firstId: firstId,
    );
  } on FormatException catch (error) {
    debugPrint('Skipping unreadable track block $firstId: $error');
    return const [];
  }
}

/// The point of a `track_tail` row.
TrackLogEntry tailRowEntry(Map<String, Object?> row, TrackLogState state) {
  return _tailRowEntry(
    row,
    sessionId: state.names[row['session_ref']! as int]!,
  );
}

TrackLogEntry _tailRowEntry(
  Map<String, Object?> row, {
  required String sessionId,
}) {
  return TrackLogEntry(
    id: row['id']! as int,
    sessionId: sessionId,
    timestampMs: row['ts']! as int,
    latitude: (row['lat']! as num).toDouble(),
    longitude: (row['lng']! as num).toDouble(),
    accuracy: (row['accuracy'] as num?)?.toDouble(),
    speed: (row['speed'] as num?)?.toDouble(),
  );
}
