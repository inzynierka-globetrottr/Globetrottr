import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('regions_world.db comprehensive integrity tests', () {
    late Database db;
    late SqfliteRegionStorage storage;
    const dbAssetPath = 'assets/data/regions_world.db';

    setUpAll(() async {
      final absPath = File(dbAssetPath).absolute.path;
      expect(
        File(absPath).existsSync(),
        isTrue,
        reason: '$absPath must exist in repository assets',
      );

      db = await openDatabase(absPath, readOnly: true);
      storage = SqfliteRegionStorage(path: absPath, autoSeed: false);
      await storage.init();
    });

    tearDownAll(() async {
      await storage.close();
      await db.close();
    });

    test('verifies total region counts and schema structure', () async {
      final totalCountResult = await db.rawQuery(
        'SELECT count(*) as count FROM regions',
      );
      final total = totalCountResult.first['count']! as int;
      expect(total, greaterThanOrEqualTo(14000));

      final typeCounts = await db.rawQuery(
        'SELECT type, count(*) as count FROM regions GROUP BY type',
      );
      final countsByType = {
        for (final row in typeCounts)
          row['type']! as String: row['count']! as int,
      };

      expect(countsByType['country'], 242);
      expect(countsByType['state'], 4596);
      expect(countsByType['city'], greaterThanOrEqualTo(9500));
      expect(countsByType['district'], 18);
    });

    test(
      'verifies valid ISO 3166-1 alpha-2 country codes without collisions',
      () async {
        final rows = await db.rawQuery(
          "SELECT id, name, code, total_area_km2 FROM regions WHERE type = 'country'",
        );
        expect(rows.length, 242);

        final seenCodes = <String, String>{};
        for (final r in rows) {
          final name = r['name']! as String;
          final code = r['code'] as String?;
          expect(
            code,
            isNotNull,
            reason: 'Country $name must have non-null code',
          );
          expect(
            code!.length,
            2,
            reason: 'Country $name code must be exactly 2 letters: $code',
          );
          expect(
            code,
            equals(code.toUpperCase()),
            reason: 'Country $name code must be uppercase',
          );

          expect(
            seenCodes.containsKey(code),
            isFalse,
            reason:
                'Duplicate country code $code for $name (already used by ${seenCodes[code]})',
          );
          seenCodes[code] = name;
        }

        // Check specific reviewed countries
        expect(seenCodes['PL'], 'Polska');
        expect(seenCodes['FR'], 'France');
        expect(seenCodes['NO'], 'Norway');
        expect(seenCodes['TW'], 'Taiwan');
        expect(seenCodes['AU'], 'Australia');
        expect(seenCodes['US'], isNotNull);
        expect(seenCodes['DE'], isNotNull);
      },
    );

    test(
      'verifies parent containment and hierarchy across countries, states and cities',
      () async {
        // 1. Australia parent verification
        final ausResult = await db.rawQuery(
          "SELECT id FROM regions WHERE name = 'Australia' AND type = 'country'",
        );
        final ausId = ausResult.first['id']! as int;

        final vicState = await db.rawQuery(
          "SELECT id, parent_id, name FROM regions WHERE code = 'AU-VIC'",
        );
        expect(
          vicState.first['parent_id'],
          ausId,
          reason: 'Victoria state must have Australia as parent',
        );

        final nswState = await db.rawQuery(
          "SELECT id, parent_id, name FROM regions WHERE code = 'AU-NSW'",
        );
        final nswId = nswState.first['id']! as int;
        expect(
          nswState.first['parent_id'],
          ausId,
          reason: 'New South Wales must have Australia as parent',
        );

        // 2. Sydney linked to New South Wales state
        final sydneyRows = await db.rawQuery(
          "SELECT id, parent_id, name FROM regions WHERE name = 'Sydney' AND parent_id = ?",
          [nswId],
        );
        expect(
          sydneyRows,
          isNotEmpty,
          reason: 'Sydney city must have New South Wales as parent',
        );

        // 3. Poland hierarchy
        final plCountry = await storage.findRegionById(1);
        expect(plCountry?.name, 'Polska');
        expect(plCountry?.type, RegionType.country);

        final malopolska = await storage.findRegionById(101);
        expect(malopolska?.name, 'Małopolskie');
        expect(malopolska?.parentId, 1);
        expect(malopolska?.type, RegionType.state);

        final krakow = await storage.findRegionById(1001);
        expect(krakow?.name, 'Kraków');
        expect(krakow?.parentId, 101);
        expect(krakow?.type, RegionType.city);

        // 4. Kraków districts linked to Kraków
        final krakowDistricts = await storage.findChildren(1001);
        expect(krakowDistricts.length, 18);
        for (final d in krakowDistricts) {
          expect(d.parentId, 1001);
          expect(d.type, RegionType.district);
          expect(
            d.geometry,
            isNotNull,
            reason: 'District ${d.name} must have non-null geometry BLOB',
          );
        }
      },
    );

    test(
      'verifies area calculation accuracy for multi-polygons and large territories',
      () async {
        // Kamienica (GUGiK MultiPolygon with enclaves)
        final kamienica = await storage.findRegionById(22160);
        expect(kamienica?.name, 'Kamienica');
        expect(kamienica?.totalAreaKm2, greaterThanOrEqualTo(90.0));
        expect(kamienica?.totalAreaKm2, closeTo(95.3, 2.0));

        // Kraków and Warsaw
        final krakow = await storage.findRegionById(1001);
        expect(krakow?.totalAreaKm2, closeTo(326.8, 1.0));

        final warsaw = await storage.findRegionById(1002);
        expect(warsaw?.totalAreaKm2, closeTo(517.2, 1.0));

        // Countries
        final rows = await db.rawQuery(
          "SELECT name, total_area_km2 FROM regions WHERE name IN ('Vietnam', 'Venezuela', 'Australia', 'United States of America')",
        );
        final areaByName = {
          for (final r in rows)
            r['name']! as String: (r['total_area_km2']! as num).toDouble(),
        };

        expect(areaByName['Vietnam'], greaterThan(300000.0));
        expect(areaByName['Venezuela'], greaterThan(800000.0));
        expect(areaByName['Australia'], greaterThan(7000000.0));
        expect(areaByName['United States of America'], greaterThan(9000000.0));
      },
    );

    test(
      'verifies point-in-polygon queries for Kraków, Plac Centralny and Sydney',
      () async {
        // Rynek Główny Kraków (50.0614, 19.9366)
        final rynekRegions = await storage.findRegionsByPoint(
          lat: 50.0614,
          lon: 19.9366,
        );
        expect(rynekRegions, isNotEmpty);
        expect(rynekRegions.any((r) => r.name == 'Stare Miasto'), isTrue);
        expect(rynekRegions.any((r) => r.name == 'Kraków'), isTrue);
        expect(rynekRegions.any((r) => r.name == 'Małopolskie'), isTrue);
        expect(rynekRegions.any((r) => r.name == 'Polska'), isTrue);

        // Plac Centralny Nowa Huta (50.0718, 20.0374)
        final nhRegions = await storage.findRegionsByPoint(
          lat: 50.0718,
          lon: 20.0374,
        );
        expect(nhRegions.any((r) => r.name == 'Nowa Huta'), isTrue);
        expect(nhRegions.any((r) => r.name == 'Kraków'), isTrue);

        // Ancestor chain consistency
        final stareMiasto = rynekRegions.firstWhere(
          (r) => r.name == 'Stare Miasto',
        );
        final ancestors = await storage.getAncestorChain(stareMiasto.id);
        expect(ancestors.map((r) => r.name).toList(), [
          'Stare Miasto',
          'Kraków',
          'Małopolskie',
          'Polska',
        ]);
      },
    );
  });
}
