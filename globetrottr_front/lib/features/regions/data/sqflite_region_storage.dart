import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteRegionStorage implements RegionStorage {
  SqfliteRegionStorage({this.path});

  final String? path;
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
    return openDatabase(
      location,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE regions (
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
          CREATE VIRTUAL TABLE regions_rtree USING rtree(
            id, min_lon, max_lon, min_lat, max_lat
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_regions_parent ON regions (parent_id)',
        );
        await db.execute('CREATE INDEX idx_regions_type ON regions (type)');
      },
    );
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
