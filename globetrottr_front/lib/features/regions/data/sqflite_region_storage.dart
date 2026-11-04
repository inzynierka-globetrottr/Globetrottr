import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_geometry.dart';
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

/// Every column but the boundary, which can be hundreds of KB for a country.
const _light =
    'id, parent_id, name, name_en, name_pl, type, code, total_area_km2, '
    'min_lat, max_lat, min_lon, max_lon';

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
  Future<Database>? _database;
  bool _versionChanged = false;
  final _boundaries = <int, Uint8List?>{};
  var _boundaryBytes = 0;
  static const _boundaryCacheBytes = 32 << 20;

  /// One open for all callers: the first ones arrive together at launch
  /// (map pill, statistics, fog catch-up) and must not copy the asset twice.
  Future<Database> get _db => _database ??= _open();

  @override
  Future<void> init() async {
    await _db;
  }

  @override
  Future<void> close() async {
    final database = _database;
    _database = null;
    await (await database)?.close();
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
      // A copy cut short (the app killed mid-write) must not look current.
      final partial = File('$location.tmp');
      await partial.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      final journal = File('$location-journal');
      if (journal.existsSync()) journal.deleteSync();
      await partial.rename(location);
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
    final found = await findRegionsByIds([id]);
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<List<Region>> findRegionsByIds(Iterable<int> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return const [];
    final db = await _db;
    final regions = <Region>[];
    for (var start = 0; start < unique.length; start += 500) {
      final batch = unique.sublist(
        start,
        (start + 500).clamp(0, unique.length),
      );
      final rows = await db.rawQuery(
        'SELECT $_light FROM regions WHERE id IN '
        '(${List.filled(batch.length, '?').join(',')})',
        batch,
      );
      regions.addAll(rows.map(Region.fromMap));
    }
    return regions;
  }

  @override
  Future<List<Region>> findChildren(int parentId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_light FROM regions WHERE parent_id = ? ORDER BY name ASC',
      [parentId],
    );
    return rows.map(Region.fromMap).toList();
  }

  @override
  Future<List<Region>> findRegionsByPoint({
    required double lat,
    required double lon,
  }) async {
    final candidates = await findRegionsInBBox(
      minLat: lat,
      minLon: lon,
      maxLat: lat,
      maxLon: lon,
    );
    final found = <Region>[];
    for (final region in candidates) {
      if (await regionContains(region, lat, lon)) found.add(region);
    }
    return found;
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
      SELECT $_light FROM regions r
      WHERE r.min_lon <= ? AND r.max_lon >= ?
        AND r.min_lat <= ? AND r.max_lat >= ?
      ORDER BY $_levelOrder, r.total_area_km2 ASC
      ''',
      [maxLon, minLon, maxLat, minLat],
    );
    return rows.map(Region.fromMap).toList();
  }

  @override
  Future<bool> regionContains(Region region, double lat, double lon) async {
    if (lat < region.minLat ||
        lat > region.maxLat ||
        lon < region.minLon ||
        lon > region.maxLon) {
      return false;
    }
    final boundary = region.geometry ?? await _boundary(region.id);
    if (boundary == null || boundary.isEmpty) return true;
    return regionGeometryContains(boundary, lat, lon);
  }

  /// Recently used boundaries, so a rebuild reads each one once.
  Future<Uint8List?> _boundary(int id) async {
    if (_boundaries.containsKey(id)) {
      final boundary = _boundaries.remove(id);
      return _boundaries[id] = boundary;
    }
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT geometry FROM regions WHERE id = ?',
      [id],
    );
    final value = rows.isEmpty ? null : rows.first['geometry'];
    final boundary = value == null
        ? null
        : Uint8List.fromList(value as List<int>);
    _boundaries[id] = boundary;
    _boundaryBytes += boundary?.length ?? 0;
    while (_boundaryBytes > _boundaryCacheBytes && _boundaries.length > 1) {
      final oldest = _boundaries.keys.first;
      _boundaryBytes -= _boundaries.remove(oldest)?.length ?? 0;
    }
    return boundary;
  }

  @override
  Future<List<Region>> getAncestorChain(int regionId) async {
    final chain = <Region>[];
    var current = await findRegionById(regionId);
    while (current != null) {
      chain.add(current);
      final parent = current.parentId;
      if (parent == null) break;
      current = await findRegionById(parent);
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
