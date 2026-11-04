import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../support/region_db_fixture.dart';
import '../../../support/region_geometry_encoder.dart';

const _poland = Region(
  id: 1,
  parentId: null,
  name: 'Polska',
  type: RegionType.country,
  code: 'PL',
  totalAreaKm2: 311934,
  minLat: 49,
  maxLat: 54.9,
  minLon: 14.1,
  maxLon: 24.2,
);

final _krakow = Region(
  id: 1000001,
  parentId: null,
  name: 'Kraków',
  type: RegionType.city,
  code: null,
  totalAreaKm2: 326.9,
  minLat: 49.97,
  maxLat: 50.13,
  minLon: 19.79,
  maxLon: 20.22,
  geometry: encodeRegionGeometry(
    rectangle(minLon: 19.79, minLat: 49.97, maxLon: 20.22, maxLat: 50.13),
  ),
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqfliteRegionStorage', () {
    late RegionStorage storage;

    setUp(() async {
      storage = SqfliteRegionStorage(path: inMemoryDatabasePath);
      await storage.init();
    });

    tearDown(() async {
      await storage.close();
    });

    test('inserts and retrieves regions by id', () async {
      const country = Region(
        id: 1,
        parentId: null,
        name: 'Polska',
        type: RegionType.country,
        code: 'PL',
        totalAreaKm2: 312696.0,
        minLat: 49.0,
        maxLat: 54.8,
        minLon: 14.1,
        maxLon: 24.1,
      );

      await storage.insertRegions([country]);

      final fetched = await storage.findRegionById(1);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Polska');
      expect(fetched.type, RegionType.country);
      expect(fetched.code, 'PL');
      expect(fetched.totalAreaKm2, 312696.0);
    });

    test(
      'finds regions containing a point ordered from leaf to root',
      () async {
        const country = Region(
          id: 1,
          parentId: null,
          name: 'Polska',
          type: RegionType.country,
          code: 'PL',
          totalAreaKm2: 312696.0,
          minLat: 49.0,
          maxLat: 55.0,
          minLon: 14.0,
          maxLon: 24.5,
        );

        const state = Region(
          id: 10,
          parentId: 1,
          name: 'Małopolskie',
          type: RegionType.state,
          code: null,
          totalAreaKm2: 15183.0,
          minLat: 49.1,
          maxLat: 50.5,
          minLon: 19.0,
          maxLon: 21.4,
        );

        const city = Region(
          id: 100,
          parentId: 10,
          name: 'Kraków',
          type: RegionType.city,
          code: null,
          totalAreaKm2: 326.8,
          minLat: 49.95,
          maxLat: 50.15,
          minLon: 19.80,
          maxLon: 20.20,
        );

        const district = Region(
          id: 1001,
          parentId: 100,
          name: 'Stare Miasto',
          type: RegionType.district,
          code: null,
          totalAreaKm2: 5.6,
          minLat: 50.05,
          maxLat: 50.07,
          minLon: 19.93,
          maxLon: 19.95,
        );

        await storage.insertRegions([country, state, city, district]);

        // Coordinates inside Stare Miasto, Kraków: 50.0614 N, 19.9383 E
        final matches = await storage.findRegionsByPoint(
          lat: 50.0614,
          lon: 19.9383,
        );
        expect(matches.length, 4);
        // Hierarchy ordered from leaf to root:
        expect(matches[0].name, 'Stare Miasto');
        expect(matches[0].type, RegionType.district);
        expect(matches[1].name, 'Kraków');
        expect(matches[1].type, RegionType.city);
        expect(matches[2].name, 'Małopolskie');
        expect(matches[2].type, RegionType.state);
        expect(matches[3].name, 'Polska');
        expect(matches[3].type, RegionType.country);
      },
    );

    test('findChildren returns all direct child regions', () async {
      const country = Region(
        id: 1,
        parentId: null,
        name: 'Polska',
        type: RegionType.country,
        code: 'PL',
        totalAreaKm2: 312696.0,
        minLat: 49.0,
        maxLat: 55.0,
        minLon: 14.0,
        maxLon: 24.5,
      );

      const state1 = Region(
        id: 10,
        parentId: 1,
        name: 'Małopolskie',
        type: RegionType.state,
        code: null,
        totalAreaKm2: 15183.0,
        minLat: 49.1,
        maxLat: 50.5,
        minLon: 19.0,
        maxLon: 21.4,
      );

      const state2 = Region(
        id: 11,
        parentId: 1,
        name: 'Mazowieckie',
        type: RegionType.state,
        code: null,
        totalAreaKm2: 35558.0,
        minLat: 51.0,
        maxLat: 53.5,
        minLon: 19.2,
        maxLon: 23.1,
      );

      await storage.insertRegions([country, state1, state2]);

      final children = await storage.findChildren(1);
      expect(children.length, 2);
      expect(
        children.map((c) => c.name),
        containsAll(['Małopolskie', 'Mazowieckie']),
      );
    });

    test('getAncestorChain resolves leaf to root chain', () async {
      const country = Region(
        id: 1,
        parentId: null,
        name: 'Polska',
        type: RegionType.country,
        code: 'PL',
        totalAreaKm2: 312696.0,
        minLat: 49.0,
        maxLat: 55.0,
        minLon: 14.0,
        maxLon: 24.5,
      );

      const state = Region(
        id: 10,
        parentId: 1,
        name: 'Małopolskie',
        type: RegionType.state,
        code: null,
        totalAreaKm2: 15183.0,
        minLat: 49.1,
        maxLat: 50.5,
        minLon: 19.0,
        maxLon: 21.4,
      );

      const city = Region(
        id: 100,
        parentId: 10,
        name: 'Kraków',
        type: RegionType.city,
        code: null,
        totalAreaKm2: 326.8,
        minLat: 49.95,
        maxLat: 50.15,
        minLon: 19.80,
        maxLon: 20.20,
      );

      await storage.insertRegions([country, state, city]);

      final ancestors = await storage.getAncestorChain(100);
      expect(ancestors.length, 3);
      expect(ancestors[0].id, 100);
      expect(ancestors[1].id, 10);
      expect(ancestors[2].id, 1);
    });

    test('installed pack regions are found by point', () async {
      final dir = await Directory.systemTemp.createTemp('regions_pack');
      addTearDown(() => dir.delete(recursive: true));
      await writeRegionsDb(
        '${dir.path}/regions_PL.db',
        version: 2,
        regions: [_krakow],
      );

      await storage.installPack('PL', 2, '${dir.path}/regions_PL.db');

      final found = await storage.findRegionsByPoint(lat: 50.06, lon: 19.94);
      expect(found.map((r) => r.name), ['Kraków']);
      expect(await storage.installedPacks(), {'PL': 2});
    });
  });

  group('SqfliteRegionStorage bundled copy', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('regions_copy');
    });

    tearDown(() => dir.delete(recursive: true));

    test('bundled DB replaces an older copy', () async {
      final local = '${dir.path}/regions_world.db';
      await writeRegionsDb(local, version: 1, regions: [_krakow]);
      final bundled = await regionsDbBytes(
        dir,
        'bundled.db',
        version: 2,
        regions: [_poland],
      );
      final storage = SqfliteRegionStorage(
        path: local,
        loadAsset: () async => ByteData.sublistView(bundled),
      );
      addTearDown(storage.close);

      expect((await storage.findRegionById(1))?.name, 'Polska');
      expect(await storage.findRegionById(_krakow.id), isNull);
      expect(await storage.consumeVersionChange(), isTrue);
      expect(await storage.consumeVersionChange(), isFalse);
    });

    test('concurrent first reads copy the bundled DB once', () async {
      final bundled = await regionsDbBytes(
        dir,
        'bundled.db',
        version: 2,
        regions: [_poland],
      );
      var loads = 0;
      final storage = SqfliteRegionStorage(
        path: '${dir.path}/regions_world.db',
        loadAsset: () async {
          loads++;
          return ByteData.sublistView(bundled);
        },
      );
      addTearDown(storage.close);

      final found = await Future.wait([
        storage.findRegionById(1),
        storage.findRegionById(1),
        storage.findChildren(1),
      ]);

      expect(loads, 1);
      expect((found.first as Region?)?.name, 'Polska');
      expect(File('${dir.path}/regions_world.db.tmp').existsSync(), isFalse);
    });

    test('current copy is not reloaded', () async {
      final local = '${dir.path}/regions_world.db';
      await writeRegionsDb(local, version: 2, regions: [_poland]);
      var loads = 0;
      final storage = SqfliteRegionStorage(
        path: local,
        loadAsset: () async {
          loads++;
          return ByteData(0);
        },
      );
      addTearDown(storage.close);

      expect((await storage.findRegionById(1))?.name, 'Polska');
      expect(loads, 0);
      expect(await storage.consumeVersionChange(), isFalse);
    });
  });
}
