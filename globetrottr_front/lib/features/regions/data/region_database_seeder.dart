import 'package:sqflite/sqflite.dart';

class SeedRegion {
  final int id;
  final int? parentId;
  final String name;
  final String type;
  final String? code;
  final double totalAreaKm2;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const SeedRegion({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
    this.code,
    required this.totalAreaKm2,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
}

class RegionDatabaseSeeder {
  static const List<SeedRegion> initialRegions = [
    // --- Countries (Admin 0) ---
    SeedRegion(
      id: 1,
      name: 'Polska',
      type: 'country',
      code: 'PL',
      totalAreaKm2: 312696.0,
      minLat: 49.00,
      maxLat: 54.84,
      minLon: 14.12,
      maxLon: 24.15,
    ),
    SeedRegion(
      id: 2,
      name: 'Niemcy',
      type: 'country',
      code: 'DE',
      totalAreaKm2: 357022.0,
      minLat: 47.27,
      maxLat: 55.06,
      minLon: 5.87,
      maxLon: 15.04,
    ),
    SeedRegion(
      id: 3,
      name: 'Czechy',
      type: 'country',
      code: 'CZ',
      totalAreaKm2: 78866.0,
      minLat: 48.55,
      maxLat: 51.06,
      minLon: 12.09,
      maxLon: 18.86,
    ),
    SeedRegion(
      id: 4,
      name: 'Słowacja',
      type: 'country',
      code: 'SK',
      totalAreaKm2: 49035.0,
      minLat: 47.73,
      maxLat: 49.61,
      minLon: 16.83,
      maxLon: 22.57,
    ),
    SeedRegion(
      id: 5,
      name: 'Ukraina',
      type: 'country',
      code: 'UA',
      totalAreaKm2: 603628.0,
      minLat: 44.38,
      maxLat: 52.38,
      minLon: 22.14,
      maxLon: 40.23,
    ),
    SeedRegion(
      id: 6,
      name: 'Francja',
      type: 'country',
      code: 'FR',
      totalAreaKm2: 643801.0,
      minLat: 41.36,
      maxLat: 51.09,
      minLon: -5.14,
      maxLon: 9.56,
    ),
    SeedRegion(
      id: 7,
      name: 'Hiszpania',
      type: 'country',
      code: 'ES',
      totalAreaKm2: 505990.0,
      minLat: 36.00,
      maxLat: 43.79,
      minLon: -9.30,
      maxLon: 3.32,
    ),
    SeedRegion(
      id: 8,
      name: 'Włochy',
      type: 'country',
      code: 'IT',
      totalAreaKm2: 301340.0,
      minLat: 36.65,
      maxLat: 47.09,
      minLon: 6.63,
      maxLon: 18.52,
    ),
    SeedRegion(
      id: 9,
      name: 'Wielka Brytania',
      type: 'country',
      code: 'GB',
      totalAreaKm2: 242495.0,
      minLat: 49.96,
      maxLat: 58.64,
      minLon: -7.57,
      maxLon: 1.77,
    ),
    SeedRegion(
      id: 10,
      name: 'Stany Zjednoczone',
      type: 'country',
      code: 'US',
      totalAreaKm2: 9833517.0,
      minLat: 24.52,
      maxLat: 49.38,
      minLon: -124.73,
      maxLon: -66.95,
    ),

    // --- States / Voivodeships (Admin 1) ---
    SeedRegion(
      id: 101,
      parentId: 1,
      name: 'Małopolskie',
      type: 'state',
      code: 'PL-12',
      totalAreaKm2: 15183.0,
      minLat: 49.10,
      maxLat: 50.50,
      minLon: 19.10,
      maxLon: 21.42,
    ),
    SeedRegion(
      id: 102,
      parentId: 1,
      name: 'Mazowieckie',
      type: 'state',
      code: 'PL-14',
      totalAreaKm2: 35558.0,
      minLat: 51.01,
      maxLat: 53.48,
      minLon: 19.26,
      maxLon: 23.13,
    ),
    SeedRegion(
      id: 103,
      parentId: 1,
      name: 'Śląskie',
      type: 'state',
      code: 'PL-24',
      totalAreaKm2: 12333.0,
      minLat: 49.39,
      maxLat: 51.10,
      minLon: 18.03,
      maxLon: 19.97,
    ),
    SeedRegion(
      id: 104,
      parentId: 1,
      name: 'Dolnośląskie',
      type: 'state',
      code: 'PL-02',
      totalAreaKm2: 19947.0,
      minLat: 50.10,
      maxLat: 51.80,
      minLon: 14.82,
      maxLon: 17.80,
    ),
    SeedRegion(
      id: 105,
      parentId: 1,
      name: 'Wielkopolskie',
      type: 'state',
      code: 'PL-30',
      totalAreaKm2: 29826.0,
      minLat: 51.35,
      maxLat: 53.65,
      minLon: 15.77,
      maxLon: 19.10,
    ),
    SeedRegion(
      id: 106,
      parentId: 1,
      name: 'Pomorskie',
      type: 'state',
      code: 'PL-22',
      totalAreaKm2: 18310.0,
      minLat: 53.50,
      maxLat: 54.83,
      minLon: 16.70,
      maxLon: 19.65,
    ),

    // --- Cities (Admin 2 / Admin 3) ---
    SeedRegion(
      id: 1001,
      parentId: 101,
      name: 'Kraków',
      type: 'city',
      totalAreaKm2: 326.8,
      minLat: 49.97,
      maxLat: 50.13,
      minLon: 19.79,
      maxLon: 20.22,
    ),
    SeedRegion(
      id: 1002,
      parentId: 102,
      name: 'Warszawa',
      type: 'city',
      totalAreaKm2: 517.2,
      minLat: 52.09,
      maxLat: 52.37,
      minLon: 20.85,
      maxLon: 21.27,
    ),
    SeedRegion(
      id: 1003,
      parentId: 104,
      name: 'Wrocław',
      type: 'city',
      totalAreaKm2: 292.8,
      minLat: 51.03,
      maxLat: 51.21,
      minLon: 16.81,
      maxLon: 17.18,
    ),
    SeedRegion(
      id: 1004,
      parentId: 105,
      name: 'Poznań',
      type: 'city',
      totalAreaKm2: 261.9,
      minLat: 52.31,
      maxLat: 52.51,
      minLon: 16.73,
      maxLon: 17.07,
    ),
    SeedRegion(
      id: 1005,
      parentId: 106,
      name: 'Gdańsk',
      type: 'city',
      totalAreaKm2: 262.0,
      minLat: 54.27,
      maxLat: 54.45,
      minLon: 18.43,
      maxLon: 18.95,
    ),
    SeedRegion(
      id: 1006,
      parentId: 103,
      name: 'Katowice',
      type: 'city',
      totalAreaKm2: 164.7,
      minLat: 50.17,
      maxLat: 50.31,
      minLon: 18.90,
      maxLon: 19.12,
    ),

    // --- Districts of Kraków (Admin 4) ---
    SeedRegion(
      id: 10001,
      parentId: 1001,
      name: 'Stare Miasto',
      type: 'district',
      totalAreaKm2: 5.57,
      minLat: 50.051,
      maxLat: 50.072,
      minLon: 19.920,
      maxLon: 19.955,
    ),
    SeedRegion(
      id: 10002,
      parentId: 1001,
      name: 'Grzegórzki',
      type: 'district',
      totalAreaKm2: 5.85,
      minLat: 50.052,
      maxLat: 50.071,
      minLon: 19.955,
      maxLon: 19.998,
    ),
    SeedRegion(
      id: 10004,
      parentId: 1001,
      name: 'Prądnik Biały',
      type: 'district',
      totalAreaKm2: 23.42,
      minLat: 50.080,
      maxLat: 50.130,
      minLon: 19.880,
      maxLon: 19.960,
    ),
    SeedRegion(
      id: 10005,
      parentId: 1001,
      name: 'Krowodrza',
      type: 'district',
      totalAreaKm2: 5.62,
      minLat: 50.065,
      maxLat: 50.082,
      minLon: 19.895,
      maxLon: 19.935,
    ),
    SeedRegion(
      id: 10008,
      parentId: 1001,
      name: 'Dębniki',
      type: 'district',
      totalAreaKm2: 27.25,
      minLat: 49.985,
      maxLat: 50.055,
      minLon: 19.820,
      maxLon: 19.935,
    ),
    SeedRegion(
      id: 10013,
      parentId: 1001,
      name: 'Podgórze',
      type: 'district',
      totalAreaKm2: 25.67,
      minLat: 50.015,
      maxLat: 50.052,
      minLon: 19.935,
      maxLon: 20.020,
    ),
    SeedRegion(
      id: 10018,
      parentId: 1001,
      name: 'Nowa Huta',
      type: 'district',
      totalAreaKm2: 65.41,
      minLat: 50.050,
      maxLat: 50.115,
      minLon: 20.020,
      maxLon: 20.220,
    ),
  ];

  static Future<void> seedIfEmpty(DatabaseExecutor db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM regions'),
        ) ??
        0;
    if (count == 0) {
      await seed(db);
    }
  }

  static Future<void> seed(DatabaseExecutor db) async {
    final batch = db.batch();
    for (final r in initialRegions) {
      batch.insert('regions', {
        'id': r.id,
        'parent_id': r.parentId,
        'name': r.name,
        'type': r.type,
        'code': r.code,
        'total_area_km2': r.totalAreaKm2,
        'min_lat': r.minLat,
        'max_lat': r.maxLat,
        'min_lon': r.minLon,
        'max_lon': r.maxLon,
        'geometry': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      batch.insert('regions_rtree', {
        'id': r.id,
        'min_lon': r.minLon,
        'max_lon': r.maxLon,
        'min_lat': r.minLat,
        'max_lat': r.maxLat,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
