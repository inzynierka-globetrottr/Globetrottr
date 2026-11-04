import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/regions_db_version.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Checks the boundary data bundled with the app, on a copy so the assets
/// stay untouched.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late SqfliteRegionStorage storage;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('bundled_regions');
    File('assets/data/regions_world.db').copySync('${dir.path}/world.db');
    storage = SqfliteRegionStorage(path: '${dir.path}/world.db');
    await storage.installPack(
      'PL',
      kBundledRegionsDbVersion,
      File('assets/data/regions/regions_PL.db').absolute.path,
    );
  });

  tearDownAll(() async {
    await storage.close();
    await dir.delete(recursive: true);
  });

  test('the bundled files carry the bundled version', () async {
    for (final path in [
      'assets/data/regions_world.db',
      'assets/data/regions/regions_PL.db',
    ]) {
      final db = await databaseFactoryFfi.openDatabase(
        File(path).absolute.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final rows = await db.rawQuery('PRAGMA user_version');
      final version = rows.single.values.single;
      await db.close();
      expect(version, kBundledRegionsDbVersion, reason: path);
    }
    final index =
        jsonDecode(File('assets/data/regions/index.json').readAsStringSync())
            as Map<String, Object?>;
    expect(index['version'], kBundledRegionsDbVersion);
  });

  test('Poland has 16 voivodeships and 380 powiats', () async {
    final krakowArea = await storage.findRegionsByPoint(
      lat: 50.0614,
      lon: 19.9366,
    );
    final poland = krakowArea.firstWhere((r) => r.type == RegionType.country);
    expect(poland.code, 'PL');
    final states = await storage.findChildren(poland.id);
    expect(states, hasLength(16));
    var counties = 0;
    for (final state in states) {
      counties += (await storage.findChildren(state.id)).length;
    }
    expect(counties, 380);
  });

  test('the Main Square lies in Stare Miasto, Kraków, Małopolskie', () async {
    final found = await storage.findRegionsByPoint(lat: 50.0617, lon: 19.9373);
    final leaf = found.first;
    expect(leaf.type, RegionType.district);
    expect(leaf.name, 'Stare Miasto');

    final chain = await storage.getAncestorChain(leaf.id);
    expect(chain.map((r) => r.type), [
      RegionType.district,
      RegionType.city,
      RegionType.county,
      RegionType.state,
      RegionType.country,
    ]);
    expect(chain[1].name, 'Kraków');
    expect(chain[3].name, 'Małopolskie');
  });

  test('a town next to Kraków is its own city', () async {
    final found = await storage.findRegionsByPoint(lat: 50.1146, lon: 19.7973);
    expect(found.first.type, RegionType.city);
    expect(found.first.name, 'Zabierzów');
  });

  for (final (name, lat, lon) in const [
    ('Kielce', 50.8703, 20.6275),
    ('Sopot', 54.4418, 18.5601),
    ('Gdańsk', 54.3520, 18.6466),
  ]) {
    test('$name is found as a city, not as its county', () async {
      final found = await storage.findRegionsByPoint(lat: lat, lon: lon);
      final chain = await storage.getAncestorChain(found.first.id);
      final city = chain.firstWhere((r) => r.type != RegionType.district);
      expect(city.type, RegionType.city);
      expect(city.name, name);
    });
  }
}
