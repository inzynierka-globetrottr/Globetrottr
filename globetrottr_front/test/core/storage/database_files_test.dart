import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/storage/database_files.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('database_files');
  });

  tearDown(() => dir.delete(recursive: true));

  void create(String name, int bytes) {
    File('${dir.path}/$name').writeAsBytesSync(List.filled(bytes, 1));
  }

  group('databaseFileBytes', () {
    test('is the size of the database file', () async {
      create('a.db', 100);

      expect(await databaseFileBytes('${dir.path}/a.db'), 100);
    });

    test(
      'adds the write-ahead log, its index and the rollback journal',
      () async {
        create('a.db', 100);
        create('a.db-wal', 50);
        create('a.db-shm', 10);
        create('a.db-journal', 5);

        expect(await databaseFileBytes('${dir.path}/a.db'), 165);
      },
    );

    test('counts a log that exists without the main file yet', () async {
      create('a.db-wal', 50);

      expect(await databaseFileBytes('${dir.path}/a.db'), 50);
    });

    test('ignores files that only look similar', () async {
      create('a.db', 100);
      create('a.db.bak', 900);
      create('b.db-wal', 900);

      expect(await databaseFileBytes('${dir.path}/a.db'), 100);
    });

    test('is zero for a database that does not exist', () async {
      expect(await databaseFileBytes('${dir.path}/missing.db'), 0);
    });

    test('is zero for an in-memory database', () async {
      expect(await databaseFileBytes(':memory:'), 0);
    });
  });
}
