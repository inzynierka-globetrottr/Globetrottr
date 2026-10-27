import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/data/sqflite_track_log_storage.dart';
import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
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

class InMemoryTrackLogStorage implements TrackLogStorage {
  final List<TrackLogEntry> _entries = [];
  int _nextId = 1;

  @override
  Future<TrackLogEntry> append(TrackLogEntry entry) async {
    final stored = TrackBlockCodec.quantize(entry).withId(_nextId++);
    _entries.add(stored);
    return stored;
  }

  @override
  Future<List<TrackLogEntry>> appendAll(List<TrackLogEntry> entries) async {
    final rounded = [
      for (final entry in entries) TrackBlockCodec.quantize(entry),
    ];
    return [
      for (final entry in rounded)
        () {
          final stored = entry.withId(_nextId++);
          _entries.add(stored);
          return stored;
        }(),
    ];
  }

  @override
  Future<void> compact() async {}

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    return _entries.where((e) => e.id! > afterId).take(limit).toList();
  }

  @override
  Future<List<TrackLogEntry>> entriesBetween(int fromMs, int toMs) async {
    return _entries
        .where((e) => e.timestampMs >= fromMs && e.timestampMs <= toMs)
        .toList()
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  }

  @override
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  }) async {
    for (var i = _entries.length - 1; i >= 0; i--) {
      final entry = _entries[i];
      if (entry.sessionId == sessionId && entry.id! <= atOrBeforeId)
        return entry;
    }
    return null;
  }

  @override
  Future<List<TrackSessionSummary>> sessionSummaries() async {
    final bySession = <String, List<TrackLogEntry>>{};
    for (final entry in _entries) {
      bySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }
    final summaries = [
      for (final group in bySession.entries)
        TrackSessionSummary(
          sessionId: group.key,
          startMs: group.value.map((e) => e.timestampMs).reduce(_min),
          endMs: group.value.map((e) => e.timestampMs).reduce(_max),
          pointCount: group.value.length,
        ),
    ]..sort((a, b) => a.startMs.compareTo(b.startMs));
    return summaries;
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;

  @override
  Future<int> count() async => _entries.length;

  @override
  Future<List<TrackLogEntry>> entriesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 20000,
  }) async {
    return _entries
        .where(
          (e) =>
              e.latitude >= south &&
              e.latitude <= north &&
              e.longitude >= west &&
              e.longitude <= east,
        )
        .take(limit)
        .toList();
  }

  @override
  Future<int> lastId() async => _entries.isEmpty ? 0 : _entries.last.id!;

  @override
  Future<int> fileBytes() async => 0;

  @override
  Future<void> clear() async => _entries.clear();

  @override
  Future<void> close() async {}
}

final trackLogStorageProvider = Provider<TrackLogStorage>((ref) {
  final storage = SqfliteTrackLogStorage();
  ref.onDispose(storage.close);
  return storage;
});
