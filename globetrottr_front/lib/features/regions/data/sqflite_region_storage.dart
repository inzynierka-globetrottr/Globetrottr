import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_database_seeder.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SqfliteRegionStorage implements RegionStorage {
  SqfliteRegionStorage({this.path, this.autoSeed = true});

  final String? path;
  final bool autoSeed;
  Database? _database;

  Future<Database> get _db async => _database ??= await _open();

  @override
  Future<void> init() async {
    await _db;
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _open() async {
    final location = path ?? 'regions_world.db';
    if (path == null) {
      await _copyAssetDbIfMissing(location);
    }
    return openDatabase(
      location,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS regions (
            id INTEGER PRIMARY KEY,
            parent_id INTEGER,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            code TEXT,
            total_area_km2 REAL NOT NULL,
            min_lat REAL NOT NULL,
            max_lat REAL NOT NULL,
            min_lon REAL NOT NULL,
            max_lon REAL NOT NULL,
            geometry BLOB
          )
        ''');
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS regions_rtree USING rtree(
            id, min_lon, max_lon, min_lat, max_lat
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_regions_parent ON regions (parent_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_regions_type ON regions (type)',
        );
        if (autoSeed) {
          await RegionDatabaseSeeder.seed(db);
        }
      },
      onOpen: (db) async {
        if (autoSeed) {
          await RegionDatabaseSeeder.seedIfEmpty(db);
        }
      },
    );
  }

  Future<void> _copyAssetDbIfMissing(String location) async {
    try {
      final dbPath = await getDatabasesPath();
      final fullPath = p.join(dbPath, location);
      final exists = await databaseExists(fullPath);
      if (!exists) {
        try {
          await Directory(p.dirname(fullPath)).create(recursive: true);
        } catch (_) {}

        final byteData = await rootBundle.load('assets/data/regions_world.db');
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await File(fullPath).writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      debugPrint('Could not unpack bundled regions_world.db asset: $e');
    }
  }

  @override
  Future<Region?> findRegionById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'regions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Region.fromMap(rows.first);
  }

  @override
  Future<List<Region>> findChildren(int parentId) async {
    final db = await _db;
    final rows = await db.query(
      'regions',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    return rows.map(Region.fromMap).toList();
  }

  @override
  Future<List<Region>> findRegionsByPoint({
    required double lat,
    required double lon,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT r.* FROM regions r
      JOIN regions_rtree tree ON r.id = tree.id
      WHERE tree.min_lon <= ? AND tree.max_lon >= ?
        AND tree.min_lat <= ? AND tree.max_lat >= ?
      ORDER BY r.total_area_km2 ASC
      ''',
      [lon, lon, lat, lat],
    );

    return rows
        .map(Region.fromMap)
        .where((r) => r.containsPoint(lat, lon))
        .toList();
  }

  @override
  Future<List<Region>> findRegionsInBBox({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT r.* FROM regions r
      JOIN regions_rtree tree ON r.id = tree.id
      WHERE tree.min_lon <= ? AND tree.max_lon >= ?
        AND tree.min_lat <= ? AND tree.max_lat >= ?
      ORDER BY r.total_area_km2 ASC
      ''',
      [maxLon, minLon, maxLat, minLat],
    );
    return rows.map(Region.fromMap).toList();
  }

  @override
  Future<List<Region>> getAncestorChain(int regionId) async {
    final chain = <Region>[];
    var current = await findRegionById(regionId);
    while (current != null) {
      chain.add(current);
      if (current.parentId == null) break;
      current = await findRegionById(current.parentId!);
    }
    return chain;
  }

  @override
  Future<void> insertRegions(Iterable<Region> regions) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final r in regions) {
        batch.insert(
          'regions',
          r.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        batch.rawInsert(
          '''
          INSERT OR REPLACE INTO regions_rtree (id, min_lon, max_lon, min_lat, max_lat)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [r.id, r.minLon, r.maxLon, r.minLat, r.maxLat],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
