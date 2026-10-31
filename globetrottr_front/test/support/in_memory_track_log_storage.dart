import 'package:globetrottr_front/features/map/data/track_block_codec.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

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
