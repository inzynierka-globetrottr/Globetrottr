import 'dart:typed_data';

import 'package:globetrottr_front/core/storage/database_files.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Fog tiles in their own database file, so clearing or rebuilding the fog
/// can never touch the track log or the pending points.
class SqfliteFogTileStorage implements FogTileStorage {
  SqfliteFogTileStorage({this.path});

  /// Database location; null uses `fog.db` in the default databases folder.
  final String? path;

  Database? _database;

  static const int _idsPerQuery = 150;

  Future<Database> get _db async => _database ??= await _open();

  Future<String> _location() async =>
      path ?? join(await getDatabasesPath(), 'fog.db');

  @override
  Future<int> fileBytes() async => databaseFileBytes(await _location());

  Future<Database> _open() async {
    final location = await _location();
    return openDatabase(
      location,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fog_tiles (
            z INTEGER NOT NULL,
            x INTEGER NOT NULL,
            y INTEGER NOT NULL,
            flag INTEGER NOT NULL,
            rev INTEGER NOT NULL,
            area REAL NOT NULL,
            data BLOB,
            PRIMARY KEY (z, x, y)
          ) WITHOUT ROWID
        ''');
        await db.execute('CREATE INDEX fog_tiles_rev ON fog_tiles (rev)');
        await db.execute('''
          CREATE TABLE fog_meta (
            key TEXT PRIMARY KEY,
            value REAL NOT NULL
          )
        ''');
      },
    );
  }

  StoredFogTile _fromRow(Map<String, Object?> row) {
    return StoredFogTile(
      id: FogTileId(row['z']! as int, row['x']! as int, row['y']! as int),
      flag: row['flag']! as int,
      rev: row['rev']! as int,
      areaM2: (row['area']! as num).toDouble(),
      bytes: row['data'] == null
          ? null
          : Uint8List.fromList(row['data']! as List<int>),
    );
  }

  @override
  Future<List<StoredFogTile>> loadTiles(Iterable<FogTileId> ids) async {
    final db = await _db;
    final list = ids.toList();
    final result = <StoredFogTile>[];
    for (var start = 0; start < list.length; start += _idsPerQuery) {
      final chunk = list.sublist(
        start,
        start + _idsPerQuery > list.length ? list.length : start + _idsPerQuery,
      );
      final where = List.filled(
        chunk.length,
        '(z = ? AND x = ? AND y = ?)',
      ).join(' OR ');
      final args = [
        for (final id in chunk) ...[id.z, id.x, id.y],
      ];
      final rows = await db.query('fog_tiles', where: where, whereArgs: args);
      result.addAll(rows.map(_fromRow));
    }
    return result;
  }

  @override
  Future<List<StoredFogTile>> loadRange({
    required int z,
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'fog_tiles',
      where: 'z = ? AND x BETWEEN ? AND ? AND y BETWEEN ? AND ?',
      whereArgs: [z, xMin, xMax, yMin, yMax],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<StoredFogTile>> changedSince(int rev, {int limit = 1000}) async {
    final db = await _db;
    final rows = await db.query(
      'fog_tiles',
      where: 'rev > ?',
      whereArgs: [rev],
      orderBy: 'rev ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> commit({
    required List<StoredFogTile> upserts,
    required Map<String, double> meta,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final tile in upserts) {
        batch.insert(
          'fog_tiles',
          {
            'z': tile.id.z,
            'x': tile.id.x,
            'y': tile.id.y,
            'flag': tile.flag,
            'rev': tile.rev,
            'area': tile.areaM2,
            'data': tile.bytes,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final entry in meta.entries) {
        batch.insert(
          'fog_meta',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<Map<String, double>> loadMeta() async {
    final db = await _db;
    final rows = await db.query('fog_meta');
    return {
      for (final row in rows)
        row['key']! as String: (row['value']! as num).toDouble(),
    };
  }

  @override
  Future<FogStorageStats> stats() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT z, COUNT(*) AS c, COALESCE(SUM(LENGTH(data)), 0) AS b '
      'FROM fog_tiles GROUP BY z',
    );
    var count = 0;
    var bytes = 0;
    final perLevel = <int, int>{};
    for (final row in rows) {
      final c = row['c']! as int;
      perLevel[row['z']! as int] = c;
      count += c;
      bytes += row['b']! as int;
    }
    return FogStorageStats(
      tileCount: count,
      totalBytes: bytes,
      tilesPerLevel: perLevel,
    );
  }

  @override
  Future<void> clear() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('fog_tiles');
      await txn.delete('fog_meta');
    });
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
