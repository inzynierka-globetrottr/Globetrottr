import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/basemap_cache.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory folder;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('basemap_cache_test');
    folder = Directory(p.join(root.path, 'tiles'));
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  BasemapCache cache() =>
      BasemapCache(directory: () async => folder, deepestZoom: 14);

  Future<void> write(String name, int bytes) async {
    await folder.create(recursive: true);
    await File(p.join(folder.path, name)).writeAsBytes(List.filled(bytes, 7));
  }

  test('a cache that was never written is empty', () async {
    final stats = await cache().stats();

    expect(stats.totalBytes, 0);
    expect(stats.vectorTiles, 0);
    expect(stats.renderedTiles, 0);
    expect(stats.deepestZoomTiles, 0);
    expect(stats.deepestZoomAreaKm2, 0);
  });

  test('tells vector tiles from rendered tiles and other files', () async {
    await write('14_9148_5554_openmaptiles.pbf', 300);
    await write('13_4574_2777_openmaptiles.pbf', 200);
    await write('globetrottr-v1a2b-14-9148-5554.png', 1000);
    await write('sprite.json', 50);
    await write('icon-atlas-globetrottr-1.png', 70);

    final stats = await cache().stats();

    expect(stats.vectorTiles, 2);
    expect(stats.vectorBytes, 500);
    expect(stats.renderedTiles, 1);
    expect(stats.renderedBytes, 1000);
    expect(stats.otherBytes, 120);
    expect(stats.totalBytes, 1620);
    expect(stats.deepestZoomTiles, 1);
    expect(
      stats.deepestZoomAreaKm2,
      closeTo(BasemapCache.tileAreaKm2(14, 5554), 1e-9),
    );
  });

  test('clearing removes every tile and keeps the folder', () async {
    await write('14_9148_5554_openmaptiles.pbf', 300);
    await write('globetrottr-v1a2b-14-9148-5554.png', 1000);

    await cache().clear();

    expect(folder.existsSync(), isTrue);
    expect(await folder.list().isEmpty, isTrue);
    expect((await cache().stats()).totalBytes, 0);
  });

  test('clearing a cache that was never written does nothing', () async {
    await cache().clear();

    expect((await cache().stats()).totalBytes, 0);
  });

  group('tile area', () {
    test('all tiles of one zoom cover the whole Earth', () {
      final rows = math.pow(2, 3).toInt();
      var area = 0.0;
      for (var y = 0; y < rows; y++) {
        area += rows * BasemapCache.tileAreaKm2(3, y);
      }

      // The Web Mercator square ends at about 85.05 degrees, so the poles
      // are out.
      final edge = math.atan((math.exp(math.pi) - math.exp(-math.pi)) / 2);
      final sphere = 4 * math.pi * math.pow(6371.0088, 2);
      expect(area, closeTo(sphere * math.sin(edge), 1));
    });

    test('a deepest zoom tile in Krakow is about 2.5 km2', () {
      expect(BasemapCache.tileAreaKm2(14, 5554), closeTo(2.46, 0.03));
    });
  });
}
