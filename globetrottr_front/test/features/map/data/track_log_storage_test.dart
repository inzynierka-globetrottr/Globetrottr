import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log/sqflite_track_log_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../support/storage_contracts.dart';
import '../../../support/in_memory_track_log_storage.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runTrackLogStorageContract(
    'in memory',
    () async => InMemoryTrackLogStorage(),
  );
  runTrackLogStorageContract(
    'sqflite',
    () async => SqfliteTrackLogStorage(path: inMemoryDatabasePath),
  );

  test('the in-memory log has no file', () async {
    expect(await InMemoryTrackLogStorage().fileBytes(), 0);
  });

  test('the sqflite log reports the size of its file', () async {
    final dir = await Directory.systemTemp.createTemp('tracks_size');
    addTearDown(() => dir.delete(recursive: true));
    final storage = SqfliteTrackLogStorage(path: '${dir.path}/tracks.db');
    addTearDown(storage.close);
    await storage.count();
    final empty = await storage.fileBytes();

    await storage.appendAll([
      for (var i = 0; i < 2000; i++)
        TrackLogEntry(
          sessionId: 'a',
          timestampMs: i,
          latitude: 50 + i * 1e-5,
          longitude: 19,
        ),
    ]);

    final filled = await storage.fileBytes();
    // 2000 packed points fit into pages the empty file already has.
    expect(filled, greaterThanOrEqualTo(empty));
    expect(filled, lessThan(empty + 2000 * 12));
  });
}
