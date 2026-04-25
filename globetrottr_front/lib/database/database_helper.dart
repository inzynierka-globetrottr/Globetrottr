import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/pending_point.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._init();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('globetrottr.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPendingPoint(PendingPoint point) async {
    final db = await database;
    return await db.insert('pending_points', point.toMap());
  }

  Future<List<PendingPoint>> getPendingPoints() async {
    final db = await database;
    final result = await db.query('pending_points', orderBy: 'timestamp ASC');

    return result.map((map) => PendingPoint.fromMap(map)).toList();
  }

  Future<void> clearPendingPoints() async {
    final db = await database;
    await db.delete('pending_points');
  }
}
