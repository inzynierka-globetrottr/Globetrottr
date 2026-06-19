import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';

class MapStorage {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('globetrottr.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPendingPoint(PendingPoint point) async {
    final db = await database;
    return db.insert('pending_points', point.toMap());
  }

  Future<List<PendingPoint>> getPendingPoints() async {
    final db = await database;
    final result = await db.query('pending_points', orderBy: 'timestamp ASC');

    return result.map(PendingPoint.fromMap).toList();
  }

  Future<void> clearPendingPoints() async {
    final db = await database;
    await db.delete('pending_points');
  }

  Future<void> deletePendingPointsByIds(List<int> ids) async {
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete(
      'pending_points',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
}

final mapStorageProvider = Provider<MapStorage>((ref) => MapStorage());
