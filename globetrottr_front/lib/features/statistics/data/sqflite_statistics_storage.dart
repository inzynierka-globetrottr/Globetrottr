import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteStatisticsStorage implements StatisticsStorage {
  SqfliteStatisticsStorage({this.path});

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
    final location = path ?? 'stats.db';
    return openDatabase(
      location,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_streak_stats (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            current_open_streak INTEGER NOT NULL DEFAULT 0,
            max_open_streak INTEGER NOT NULL DEFAULT 0,
            last_open_date TEXT,
            current_recording_streak INTEGER NOT NULL DEFAULT 0,
            max_recording_streak INTEGER NOT NULL DEFAULT 0,
            last_recording_date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE user_region_stats (
            region_id INTEGER PRIMARY KEY,
            discovered_area_m2 REAL NOT NULL DEFAULT 0.0,
            discovery_percentage REAL NOT NULL DEFAULT 0.0,
            first_visit_ms INTEGER,
            last_visit_ms INTEGER,
            visits_count INTEGER DEFAULT 0,
            time_spent_seconds INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE fog_tile_regions (
            z INTEGER NOT NULL,
            x INTEGER NOT NULL,
            y INTEGER NOT NULL,
            region_id INTEGER NOT NULL,
            PRIMARY KEY (z, x, y)
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_exploration_stats (
            date TEXT PRIMARY KEY,
            opened_app INTEGER NOT NULL DEFAULT 1,
            new_area_m2 REAL NOT NULL DEFAULT 0.0,
            distance_m REAL NOT NULL DEFAULT 0.0,
            duration_seconds INTEGER NOT NULL DEFAULT 0,
            walk_distance_m REAL DEFAULT 0.0,
            bike_distance_m REAL DEFAULT 0.0,
            run_distance_m REAL DEFAULT 0.0,
            other_distance_m REAL DEFAULT 0.0,
            new_streets_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE user_records (
            record_key TEXT PRIMARY KEY,
            numeric_value REAL NOT NULL,
            label TEXT,
            timestamp_ms INTEGER
          )
        ''');
      },
    );
  }

  @override
  Future<UserStreakStats> loadStreakStats() async {
    final db = await _db;
    final rows = await db.query(
      'user_streak_stats',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      return UserStreakStats.empty;
    }
    return UserStreakStats.fromMap(rows.first);
  }

  @override
  Future<void> saveStreakStats(UserStreakStats stats) async {
    final db = await _db;
    await db.insert(
      'user_streak_stats',
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<UserRegionStats?> getRegionStats(int regionId) async {
    final db = await _db;
    final rows = await db.query(
      'user_region_stats',
      where: 'region_id = ?',
      whereArgs: [regionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRegionStats.fromMap(rows.first);
  }

  @override
  Future<List<UserRegionStats>> getAllRegionStats() async {
    final db = await _db;
    final rows = await db.query('user_region_stats');
    return rows.map(UserRegionStats.fromMap).toList();
  }

  @override
  Future<void> saveRegionStats(Iterable<UserRegionStats> stats) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in stats) {
        batch.insert(
          'user_region_stats',
          s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> replaceRegionStats(Iterable<UserRegionStats> stats) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('user_region_stats');
      final batch = txn.batch();
      for (final s in stats) {
        batch.insert('user_region_stats', s.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> clearRegionStats() async {
    final db = await _db;
    await db.delete('user_region_stats');
    await db.delete('fog_tile_regions');
    await db.delete(
      'user_records',
      where: 'record_key = ?',
      whereArgs: ['stats_backfilled'],
    );
  }

  @override
  Future<int?> getCachedTileRegion({
    required int z,
    required int x,
    required int y,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'fog_tile_regions',
      columns: ['region_id'],
      where: 'z = ? AND x = ? AND y = ?',
      whereArgs: [z, x, y],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['region_id'] as int?;
  }

  @override
  Future<void> cacheTileRegion({
    required int z,
    required int x,
    required int y,
    required int regionId,
  }) async {
    final db = await _db;
    await db.insert(
      'fog_tile_regions',
      {'z': z, 'x': x, 'y': y, 'region_id': regionId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<DailyExplorationStats?> getDailyStats(String date) async {
    final db = await _db;
    final rows = await db.query(
      'daily_exploration_stats',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyExplorationStats.fromMap(rows.first);
  }

  @override
  Future<List<DailyExplorationStats>> getDailyStatsRange({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'daily_exploration_stats',
      where: 'date >= ? AND date <= ?',
      whereArgs: [fromDate, toDate],
      orderBy: 'date ASC',
    );
    return rows.map(DailyExplorationStats.fromMap).toList();
  }

  @override
  Future<DailyExplorationStats?> getBestDayStats() async {
    final db = await _db;
    final rows = await db.query(
      'daily_exploration_stats',
      orderBy: 'new_area_m2 DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyExplorationStats.fromMap(rows.first);
  }

  @override
  Future<void> saveDailyStats(DailyExplorationStats stats) async {
    final db = await _db;
    await db.insert(
      'daily_exploration_stats',
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<double?> getRecord(String key) async {
    final db = await _db;
    final rows = await db.query(
      'user_records',
      columns: ['numeric_value'],
      where: 'record_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['numeric_value'] as num?)?.toDouble();
  }

  @override
  Future<UserRecordEntry?> getRecordEntry(String key) async {
    final db = await _db;
    final rows = await db.query(
      'user_records',
      where: 'record_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserRecordEntry(
      key: key,
      value: (row['numeric_value']! as num).toDouble(),
      label: row['label'] as String?,
      timestampMs: (row['timestamp_ms'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> setRecordIfMax(
    String key,
    double value, {
    String? label,
    int? timestampMs,
  }) async {
    final db = await _db;
    final current = await getRecord(key);
    if (current == null || value > current) {
      await db.insert(
        'user_records',
        {
          'record_key': key,
          'numeric_value': value,
          'label': label,
          'timestamp_ms': timestampMs ?? DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
