import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/sqflite_fog_tile_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../support/storage_contracts.dart';
import '../../../support/in_memory_fog_tile_storage.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runFogTileStorageContract('in memory', () async => InMemoryFogTileStorage());
  runFogTileStorageContract(
    'sqflite',
    () async => SqfliteFogTileStorage(path: inMemoryDatabasePath),
  );

  test('the in-memory storage has no file', () async {
    expect(await InMemoryFogTileStorage().fileBytes(), 0);
  });

  test('the sqflite storage reports the size of its file', () async {
    final dir = await Directory.systemTemp.createTemp('fog_size');
    addTearDown(() => dir.delete(recursive: true));
    final storage = SqfliteFogTileStorage(path: '${dir.path}/fog.db');
    addTearDown(storage.close);

    expect(await storage.fileBytes(), 0);
    await storage.commit(
      upserts: [
        for (var x = 0; x < 200; x++)
          StoredFogTile(
            id: FogTileId(12, x, 3),
            flag: 2,
            rev: 1,
            areaM2: 0,
            bytes: Uint8List.fromList(List.filled(400, 7)),
          ),
      ],
      meta: const {'rev': 1},
    );

    final size = await storage.fileBytes();
    expect(size, greaterThan(200 * 400));
    expect(
      size,
      greaterThanOrEqualTo(await File('${dir.path}/fog.db').length()),
    );
  });
}
