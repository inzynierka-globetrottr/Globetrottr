import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  });
}
