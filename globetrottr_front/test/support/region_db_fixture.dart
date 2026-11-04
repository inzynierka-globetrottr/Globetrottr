import 'dart:io';
import 'dart:typed_data';

import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Writes a regions database in the format of `tool/regions/build_regions.py`.
Future<void> writeRegionsDb(
  String path, {
  required int version,
  required List<Region> regions,
}) async {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final db = await databaseFactoryFfi.openDatabase(path);
  await db.execute('''
    CREATE TABLE regions (
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
  for (final region in regions) {
    await db.insert('regions', region.toMap());
  }
  await db.execute('PRAGMA user_version = $version');
  await db.close();
}

Future<Uint8List> regionsDbBytes(
  Directory dir,
  String name, {
  required int version,
  required List<Region> regions,
}) async {
  final path = '${dir.path}/$name';
  await writeRegionsDb(path, version: version, regions: regions);
  return File(path).readAsBytes();
}
