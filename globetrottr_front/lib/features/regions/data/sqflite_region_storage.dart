import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/regions_db_version.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Finest level first, so a city that is as large as its county (a city with
/// county rights) or larger (one whose boundary takes in water) still comes
/// before the county.
const _levelOrder =
    "CASE r.type WHEN 'district' THEN 0 WHEN 'city' THEN 1 "
    "WHEN 'county' THEN 2 WHEN 'state' THEN 3 ELSE 4 END";

const _columns =
    'id, parent_id, name, name_en, name_pl, type, code, total_area_km2, '
    'min_lat, max_lat, min_lon, max_lon, geometry';

class SqfliteRegionStorage implements RegionStorage {
  /// Without [path] the bundled database is copied to the databases folder.
  /// With [path] and no [loadAsset] the database at [path] is used as it is
  /// (tests).
  SqfliteRegionStorage({
    this.path,
    Future<ByteData> Function()? loadAsset,
    this.bundledVersion = kBundledRegionsDbVersion,
  }) : _loadAsset =
           loadAsset ??
           (path == null
               ? () => rootBundle.load('assets/data/regions_world.db')
               : null);

  final String? path;
  final int bundledVersion;
  final Future<ByteData> Function()? _loadAsset;
  Database? _database;
  bool _versionChanged = false;

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
    final location =
        path ?? p.join(await getDatabasesPath(), 'regions_world.db');
    final loadAsset = _loadAsset;
    if (loadAsset != null) await _copyIfOutdated(location, loadAsset);
    final db = await openDatabase(location);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS regions (
        id INTEGER PRIMARY KEY,
        parent_id INTEGER,
        name TEXT NOT NULL,
        name_en TEXT,
        name_pl TEXT,
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_regions_bbox ON regions '
      '(min_lon, max_lon, min_lat, max_lat)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_regions_parent ON regions (parent_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS installed_packs (
        country TEXT PRIMARY KEY,
        version INTEGER NOT NULL
      )
    ''');
    return db;
  }

  /// Reads only the version of the local copy; the asset (tens of MB) is
  /// loaded just when it has to replace it.
  Future<void> _copyIfOutdated(
    String location,
    Future<ByteData> Function() loadAsset,
  ) async {
    final file = File(location);
    final existed = file.existsSync();
    if (existed && await _localVersion(location) == bundledVersion) return;
    try {
      final data = await loadAsset();
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      _versionChanged = existed;
    } catch (e) {
      debugPrint('Could not unpack the bundled regions_world.db: $e');
    }
  }

  Future<int?> _localVersion(String location) async {
    try {
      final db = await openDatabase(location, readOnly: true);
      try {
        return Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version'));
      } finally {
        await db.close();
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> consumeVersionChange() async {
    await _db;
    final changed = _versionChanged;
    _versionChanged = false;
    return changed;
  }

  @override
  Future<Map<String, int>> installedPacks() async {
    final db = await _db;
    final rows = await db.query('installed_packs');
    return {
      for (final row in rows) row['country']! as String: row['version']! as int,
    };
  }

  @override
  Future<void> installPack(String country, int version, String packPath) async {
    final db = await _db;
    await db.execute('ATTACH DATABASE ? AS pack', [packPath]);
    try {
      await db.transaction((txn) async {
        await txn.execute(
          'DELETE FROM regions WHERE id IN (SELECT id FROM pack.regions)',
        );
        await txn.execute(
          'INSERT INTO regions ($_columns) SELECT $_columns FROM pack.regions',
        );
        await txn.insert('installed_packs', {
          'country': country,
          'version': version,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } finally {
      await db.execute('DETACH DATABASE pack');
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
      WHERE r.min_lon <= ? AND r.max_lon >= ?
        AND r.min_lat <= ? AND r.max_lat >= ?
      ORDER BY $_levelOrder, r.total_area_km2 ASC
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
      WHERE r.min_lon <= ? AND r.max_lon >= ?
        AND r.min_lat <= ? AND r.max_lat >= ?
      ORDER BY $_levelOrder, r.total_area_km2 ASC
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
      }
      await batch.commit(noResult: true);
    });
  }
}
