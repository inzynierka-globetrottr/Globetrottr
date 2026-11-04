import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_pack_service.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../support/region_db_fixture.dart';
import '../../../support/region_geometry_encoder.dart';

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

  late Directory dir;
  late SqfliteRegionStorage storage;
  late Uint8List pack;
  late Map<String, int> loads;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('region_packs');
    storage = SqfliteRegionStorage(path: inMemoryDatabasePath);
    pack = await regionsDbBytes(
      dir,
      'regions_PL.db',
      version: 2,
      regions: [_krakow],
    );
    loads = {};
  });

  tearDown(() async {
    await storage.close();
    await dir.delete(recursive: true);
  });

  RegionPackService service({int indexVersion = 2}) => RegionPackService(
    storage: storage,
    tempDir: () async => dir.path,
    loadAsset: (path) async {
      loads[path] = (loads[path] ?? 0) + 1;
      if (path == 'assets/data/regions/index.json') {
        final index = {
          'version': indexVersion,
          'packs': [
            {'country': 'PL', 'file': 'regions_PL.db', 'bytes': pack.length},
          ],
        };
        return ByteData.sublistView(utf8.encode(jsonEncode(index)));
      }
      if (path == 'assets/data/regions/regions_PL.db') {
        return ByteData.sublistView(pack);
      }
      throw StateError('no asset $path');
    },
  );

  test('installs the bundled file of a country', () async {
    expect(await service().ensurePack('PL'), isTrue);

    final found = await storage.findRegionsByPoint(lat: 50.06, lon: 19.94);
    expect(found.map((r) => r.name), ['Kraków']);
  });

  test('an installed country is not copied again', () async {
    final packs = service();
    await packs.ensurePack('PL');

    expect(await packs.ensurePack('PL'), isFalse);
    expect(loads['assets/data/regions/regions_PL.db'], 1);
  });

  test('a country without a file installs nothing', () async {
    expect(await service().ensurePack('XX'), isFalse);
    expect(await storage.installedPacks(), isEmpty);
  });

  test('a newer bundled version is installed again', () async {
    await service().ensurePack('PL');

    expect(await service(indexVersion: 3).ensurePack('PL'), isTrue);
    expect(await storage.installedPacks(), {'PL': 3});
    final found = await storage.findRegionsByPoint(lat: 50.06, lon: 19.94);
    expect(found, hasLength(1));
  });
}
