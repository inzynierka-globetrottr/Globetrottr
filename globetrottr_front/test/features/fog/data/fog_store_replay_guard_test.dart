import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_writer.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';
import '../../../support/in_memory_track_log_storage.dart';

const _points = 200;

Future<FogStore> _open(FogTileStorage storage) {
  return FogStore.open(storage, flushDelay: const Duration(hours: 1));
}

/// Writes the mark a replay leaves when it starts a step, as if the app died
/// in it.
Future<void> _leaveMark(
  FogTileStorage storage, {
  required int after,
  required int attempts,
}) {
  return storage.commit(
    upserts: const [],
    meta: {
      ...FogTileWriter.compatibilityMeta(baseZoom: FogConfig.baseZoom),
      'replayStepAfter': after.toDouble(),
      'replayAttempts': attempts.toDouble(),
    },
  );
}

Future<InMemoryTrackLogStorage> _walkLog() async {
  final log = _RecordingTrackLog();
  await log.appendAll(walkEast('a', points: _points));
  return log;
}

class _RecordingTrackLog extends InMemoryTrackLogStorage {
  final List<int> limits = [];
  bool failNextLookup = false;

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) {
    limits.add(limit);
    return super.entriesAfter(afterId, limit: limit);
  }

  @override
  Future<TrackLogEntry?> lastEntryOfSession(
    String sessionId, {
    required int atOrBeforeId,
  }) {
    if (failNextLookup) {
      failNextLookup = false;
      throw StateError('the step failed');
    }
    return super.lastEntryOfSession(sessionId, atOrBeforeId: atOrBeforeId);
  }
}

Future<double> _coverageAtIndex(FogStore store, int index) {
  final at = offsetMeters(krakowLat, krakowLng, east: index * 10);
  return coverageAt(store, at.lat, at.lng);
}

void main() {
  late InMemoryFogTileStorage storage;

  setUp(() => storage = InMemoryFogTileStorage());

  test('a finished replay leaves no mark', () async {
    final log = await _walkLog();
    final store = await _open(storage);

    await store.replayFrom(log, useIsolate: false);

    expect((await storage.loadMeta())['replayAttempts'] ?? 0, 0);
    await store.dispose();
  });

  test('a step that fails leaves a mark of one attempt', () async {
    final log = await _walkLog() as _RecordingTrackLog;
    log.failNextLookup = true;
    final store = await _open(storage);

    await expectLater(
      store.replayFrom(log, useIsolate: false),
      throwsStateError,
    );

    final meta = await storage.loadMeta();
    expect(meta['replayAttempts'], 1);
    expect(meta['replayStepAfter'], 0);
    await store.dispose();
  });

  test('a mark written before any flush survives a restart', () async {
    final log = await _walkLog() as _RecordingTrackLog;
    log.failNextLookup = true;
    final store = await _open(storage);
    await expectLater(
      store.replayFrom(log, useIsolate: false),
      throwsStateError,
    );
    await store.dispose();

    final reopened = await _open(storage);

    final meta = await storage.loadMeta();
    expect(meta['replayAttempts'], 1);
    expect(reopened.lastAppliedLogId, 0);
    await reopened.dispose();
  });

  test('a step left unfinished once is retried in small steps', () async {
    final log = await _walkLog() as _RecordingTrackLog;
    await _leaveMark(storage, after: 0, attempts: 1);
    final store = await _open(storage);

    await store.replayFrom(log, useIsolate: false);

    expect(log.limits.first, FogConfig.retryStepEntries);
    expect(store.lastAppliedLogId, _points);
    expect(store.diagnostics.skippedLogEntries, 0);
    expect(await _coverageAtIndex(store, 10), 1);
    expect(await _coverageAtIndex(store, _points - 1), 1);
    await store.dispose();
  });

  test('a mark of another step does not change the step size', () async {
    final log = await _walkLog() as _RecordingTrackLog;
    await _leaveMark(storage, after: 77, attempts: 2);
    final store = await _open(storage);

    await store.replayFrom(log, useIsolate: false);

    expect(log.limits.first, isNot(FogConfig.retryStepEntries));
    expect(store.diagnostics.skippedLogEntries, 0);
    await store.dispose();
  });

  test('a step that already failed twice is skipped', () async {
    final log = await _walkLog() as _RecordingTrackLog;
    await _leaveMark(
      storage,
      after: 0,
      attempts: FogConfig.maxReplayStepAttempts,
    );
    final store = await _open(storage);

    await store.replayFrom(log, useIsolate: false);

    const skipped = FogConfig.retryStepEntries;
    expect(store.diagnostics.skippedLogEntries, skipped);
    expect(store.lastAppliedLogId, _points);
    expect(await _coverageAtIndex(store, 10), 0);
    expect(await _coverageAtIndex(store, skipped + 10), 1);
    expect(await _coverageAtIndex(store, _points - 1), 1);
    expect((await storage.loadMeta())['replayAttempts'] ?? 0, 0);
    await store.dispose();
  });

  test('the skipped entries are remembered after a restart', () async {
    final log = await _walkLog();
    await _leaveMark(
      storage,
      after: 0,
      attempts: FogConfig.maxReplayStepAttempts,
    );
    final store = await _open(storage);
    await store.replayFrom(log, useIsolate: false);
    await store.flush();
    await store.dispose();

    final reopened = await _open(storage);

    expect(reopened.diagnostics.skippedLogEntries, FogConfig.retryStepEntries);
    await reopened.dispose();
  });

  test('a rebuild forgets the skipped entries and draws everything', () async {
    final log = await _walkLog();
    await _leaveMark(
      storage,
      after: 0,
      attempts: FogConfig.maxReplayStepAttempts,
    );
    final store = await _open(storage);
    await store.replayFrom(log, useIsolate: false);

    await store.rebuildFrom(log, useIsolate: false);

    expect(store.diagnostics.skippedLogEntries, 0);
    expect(await _coverageAtIndex(store, 10), 1);
    await store.dispose();
  });
}
