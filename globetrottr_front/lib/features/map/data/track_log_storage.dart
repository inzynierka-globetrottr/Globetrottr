import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/data/track_log/sqflite_track_log_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

abstract class TrackLogStorage {
  /// Stores a fix and returns it as it is stored: with its number and with
  /// the position, accuracy and speed rounded the way the log keeps them.
  Future<TrackLogEntry> append(TrackLogEntry entry);

  /// Stores fixes in order. A position that is not a real number makes the
  /// whole batch fail before anything is written.
  Future<List<TrackLogEntry>> appendAll(List<TrackLogEntry> entries);

  /// Packs the newest points into their final, compact form. Safe to call
  /// at any time; nothing readable changes.
  Future<void> compact();

  /// Entries with an id greater than [afterId], oldest first.
  Future<List<TrackLogEntry>> entriesAfter(int afterId, {int limit = 5000});

  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs);

  /// Latest entry of [sessionId] whose id is at most [atOrBeforeId].
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  });

  Future<List<TrackSessionSummary>> sessionSummaries();

  Future<int> count();

  /// Entries whose position lies inside the box (borders included), oldest
  /// first, at most [limit] of them.
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  });

  /// Id of the newest entry, or 0 when the log is empty.
  Future<int> lastId();

  /// Size on disk of the database file and its journal files.
  Future<int> fileBytes();

  Future<void> clear();

  Future<void> close();
}

final trackLogStorageProvider = Provider<TrackLogStorage>((ref) {
  final storage = SqfliteTrackLogStorage();
  ref.onDispose(storage.close);
  return storage;
});
