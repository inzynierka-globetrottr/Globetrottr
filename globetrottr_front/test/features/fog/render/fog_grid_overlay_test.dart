import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

BitmapFogPainter _painter(
  MapCamera camera, {
  required bool grid,
  dynamic source,
}) {
  return BitmapFogPainter(
    camera: camera,
    source: source,
    options: FogRenderOptions(softEdge: false, showGrid: grid),
  );
}

/// Strongest alpha in the 5x5 pixels around a world pixel of a tile corner.
int _alphaAtCorner(
  int Function(int x, int y) alpha,
  MapCamera camera,
  int z,
  double worldX,
  double worldY,
) {
  final at = screenOf(
    camera,
    FogMercator.yToLat(worldY, z),
    FogMercator.xToLng(worldX, z),
  );
  var strongest = 0;
  for (var dx = -2; dx <= 2; dx++) {
    for (var dy = -2; dy <= 2; dy++) {
      final x = at.dx.round() + dx;
      final y = at.dy.round() + dy;
      if (x < 0 || x >= 400 || y < 0 || y >= 800) continue;
      strongest = math.max(strongest, alpha(x, y));
    }
  }
  return strongest;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FogRenderOptions.showGrid', () {
    test('is off by default', () {
      expect(const FogRenderOptions().showGrid, isFalse);
    });

    test('is part of copyWith, equality and hash code', () {
      const base = FogRenderOptions();

      final shown = base.copyWith(showGrid: true);

      expect(shown.showGrid, isTrue);
      expect(shown, isNot(base));
      expect(shown.hashCode, isNot(base.hashCode));
      expect(shown.copyWith(softEdge: false).showGrid, isTrue);
      expect(base.copyWith(showGrid: false), base);
    });
  });

  group('tile grid overlay', () {
    test('draws bright lines on the tile borders only when enabled', () async {
      final camera = cameraAt();
      final tile = tileOf(krakowLat, krakowLng, 17);
      final cornerX = (tile.x + 1) * 256.0;
      final cornerY = (tile.y + 1) * 256.0;

      final off = await renderAlpha(_painter(camera, grid: false));
      final on = await renderAlpha(_painter(camera, grid: true));

      expect(
        _alphaAtCorner(off, camera, 17, cornerX, cornerY),
        closeTo(191, 1),
      );
      expect(
        _alphaAtCorner(on, camera, 17, cornerX, cornerY),
        greaterThan(240),
      );
    });

    test('leaves the inside of a tile untouched', () async {
      final camera = cameraAt();
      final tile = tileOf(krakowLat, krakowLng, 17);
      final centerX = (tile.x + 0.5) * 256.0;
      final centerY = (tile.y + 0.5) * 256.0;

      final on = await renderAlpha(_painter(camera, grid: true));

      final at = screenOf(
        camera,
        FogMercator.yToLat(centerY, 17),
        FogMercator.xToLng(centerX, 17),
      );
      expect(
        on(at.dx.round() + 60, at.dy.round() + 70),
        closeTo(191, 1),
        reason: 'away from lines and labels',
      );
    });

    test('follows the tile borders on a rotated map', () async {
      final camera = cameraAt(rotation: 37);
      final tile = tileOf(krakowLat, krakowLng, 17);

      final on = await renderAlpha(_painter(camera, grid: true));

      final strongestCorner = [
        for (final dx in [0, 1])
          for (final dy in [0, 1])
            _alphaAtCorner(
              on,
              camera,
              17,
              (tile.x + dx) * 256.0,
              (tile.y + dy) * 256.0,
            ),
      ].reduce(math.max);
      expect(strongestCorner, greaterThan(240));
    });

    test('uses the level of the current zoom', () async {
      final camera = cameraAt(zoom: 14);
      final tile = tileOf(krakowLat, krakowLng, 14);

      final on = await renderAlpha(_painter(camera, grid: true));

      expect(
        _alphaAtCorner(on, camera, 14, tile.x * 256.0, tile.y * 256.0),
        greaterThan(240),
      );
    });

    test('works with a tile source and marks tiles with fog data', () async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);

      final off = await renderAlpha(
        _painter(camera, grid: false, source: source),
      );
      final on = await renderAlpha(
        _painter(camera, grid: true, source: source),
      );

      final tile = tileOf(krakowLat, krakowLng, 17);
      final corner = _alphaAtCorner(
        on,
        camera,
        17,
        (tile.x + 1) * 256.0,
        (tile.y + 1) * 256.0,
      );
      expect(corner, greaterThan(240));
      expect(off(200, 400), 0);
      source.dispose();
      await store.dispose();
    });

    test('draws the tile names as text', () async {
      final camera = cameraAt();

      final off = await renderAlpha(_painter(camera, grid: false));
      final on = await renderAlpha(_painter(camera, grid: true));

      var changed = 0;
      for (var y = 0; y < 800; y += 2) {
        for (var x = 0; x < 400; x += 2) {
          if ((on(x, y) - off(x, y)).abs() > 20) changed++;
        }
      }
      expect(changed, greaterThan(150));
    });

    test('is skipped for a broken camera', () async {
      final broken = cameraAt(zoom: double.nan);

      final on = await renderAlpha(_painter(broken, grid: true));

      expect(on(200, 400), closeTo(191, 1));
    });

    test('is skipped when too many tiles would be drawn', () async {
      final camera = cameraAt(zoom: 17.4, lat: 50, lng: 19.9);
      final tiny = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(50, 20),
        zoom: 3,
        rotation: 0,
        nonRotatedSize: const math.Point<double>(400, 800),
      );

      final on = await renderAlpha(_painter(tiny, grid: true));

      expect(camera.zoom, 17.4);
      expect(on(5, 5), greaterThan(0));
    });

    test('repaints when the option changes', () {
      final camera = cameraAt();

      expect(
        _painter(
          camera,
          grid: true,
        ).shouldRepaint(_painter(camera, grid: false)),
        isTrue,
      );
    });
  });
}
