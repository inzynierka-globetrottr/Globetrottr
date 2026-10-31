import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

BitmapFogPainter _painter(
  MapCamera camera, {
  required bool raw,
  bool softEdge = false,
  dynamic source,
  LatLng? head,
}) {
  return BitmapFogPainter(
    camera: camera,
    source: source,
    head: head == null ? null : ValueNotifier<LatLng?>(head),
    options: FogRenderOptions(softEdge: softEdge, rawPixels: raw),
  );
}

/// Number of times the alpha changes between consecutive rows of column [x].
int _changesDown(int Function(int x, int y) alpha, int x, int from, int to) {
  var changes = 0;
  for (var y = from + 1; y <= to; y++) {
    if (alpha(x, y) != alpha(x, y - 1)) changes++;
  }
  return changes;
}

/// Number of separate groups of consecutive pixels brighter than the fog.
int _brightRuns(List<int> row) {
  var runs = 0;
  var inside = false;
  for (final value in row) {
    final bright = value > 195;
    if (bright && !inside) runs++;
    inside = bright;
  }
  return runs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FogRenderOptions.rawPixels', () {
    test('is off by default and part of the value', () {
      const base = FogRenderOptions();

      expect(base.rawPixels, isFalse);
      expect(base.copyWith(rawPixels: true).rawPixels, isTrue);
      expect(base.copyWith(rawPixels: true), isNot(base));
      expect(
        base.copyWith(rawPixels: true).hashCode,
        isNot(base.hashCode),
      );
      expect(
        base.copyWith(rawPixels: true).copyWith(showGrid: true).rawPixels,
        isTrue,
      );
    });
  });

  group('raw fog pixels', () {
    // Two and a half levels above the base zoom one fog pixel is about 5.3 screen pixels wide: big enough
    // to see the blocks, still too small for the lines between them.
    Future<(int Function(int, int), int Function(int, int))> bothViews() async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final camera = cameraAt(
        zoom: FogConfig.baseZoom + 2.4,
        lng: offsetMeters(krakowLat, krakowLng, east: 145).lng,
      );
      final source = await readySource(store, camera);
      final raw = await renderAlpha(
        _painter(camera, raw: true, source: source),
      );
      final smooth = await renderAlpha(
        _painter(camera, raw: false, softEdge: true, source: source),
      );
      source.dispose();
      await store.dispose();
      return (raw, smooth);
    }

    test('shows blocky pixels where the normal view is smooth', () async {
      final (raw, smooth) = await bothViews();

      // The trail edge is about 16 fog pixels (86 rows) above the middle.
      final rawChanges = _changesDown(raw, 200, 240, 340);
      final smoothChanges = _changesDown(smooth, 200, 240, 340);

      expect(rawChanges, greaterThan(0));
      expect(rawChanges, lessThanOrEqualTo(6));
      expect(smoothChanges, greaterThan(rawChanges * 2));
    });

    test('keeps every fog pixel one flat colour', () async {
      final (raw, _) = await bothViews();

      final changeRows = [
        for (var y = 241; y <= 340; y++)
          if (raw(200, y) != raw(200, y - 1)) y,
      ];
      expect(changeRows.length, greaterThan(1));
      for (var i = 1; i < changeRows.length; i++) {
        expect(
          changeRows[i] - changeRows[i - 1],
          greaterThanOrEqualTo(5),
          reason: 'a fog pixel is at least 5 screen pixels tall',
        );
      }
    });

    test('ignores the soft edge blur', () async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final camera = cameraAt(zoom: FogConfig.baseZoom + 1.5);
      final source = await readySource(store, camera);

      final plain = await renderAlpha(
        _painter(camera, raw: true, source: source),
      );
      final blurred = await renderAlpha(
        _painter(camera, raw: true, softEdge: true, source: source),
      );

      for (var y = 0; y < 800; y += 7) {
        for (var x = 0; x < 400; x += 7) {
          expect(blurred(x, y), plain(x, y), reason: '($x, $y)');
        }
      }
      source.dispose();
      await store.dispose();
    });

    test('does not draw the live fog', () async {
      final camera = cameraAt();
      const player = LatLng(krakowLat, krakowLng);
      final store = await openStore();
      final source = await readySource(store, camera);

      final normal = await renderAlpha(
        _painter(camera, raw: false, source: source, head: player),
      );
      final raw = await renderAlpha(
        _painter(camera, raw: true, source: source, head: player),
      );
      source.dispose();
      await store.dispose();

      expect(normal(200, 400), 0);
      expect(raw(200, 400), closeTo(191, 1));
    });

    test('draws lines between fog pixels once they are big enough', () async {
      final camera = cameraAt(zoom: FogConfig.baseZoom + 3);

      final alpha = await renderAlpha(_painter(camera, raw: true));

      // A line is a run of bright pixels (anti-aliasing can make it two wide).
      // Rows between the horizontal lines only cross the vertical ones: one
      // line per 8 screen pixels along 80 pixels.
      final runs = [
        for (var y = 300; y < 308; y++)
          _brightRuns([for (var x = 0; x < 80; x++) alpha(x, y)]),
      ];
      expect(runs.reduce((a, b) => a > b ? a : b), inInclusiveRange(9, 11));
    });

    test('draws no pixel lines when the pixels are small', () async {
      final camera = cameraAt();

      final alpha = await renderAlpha(_painter(camera, raw: true));

      for (var x = 0; x < 80; x++) {
        expect(alpha(x, 300), closeTo(191, 1));
      }
    });

    test('keeps the lines aligned with the pixels of a rotated map', () async {
      final camera = cameraAt(zoom: FogConfig.baseZoom + 3, rotation: 33);

      final alpha = await renderAlpha(_painter(camera, raw: true));

      var bright = 0;
      for (var x = 0; x < 400; x++) {
        if (alpha(x, 300) > 200) bright++;
      }
      expect(bright, greaterThan(20));
    });

    test('survives a broken camera', () async {
      final alpha = await renderAlpha(
        _painter(cameraAt(zoom: double.nan), raw: true),
      );

      expect(alpha(200, 400), closeTo(191, 1));
    });

    test('repaints when the option changes', () {
      final camera = cameraAt();

      expect(
        _painter(camera, raw: true).shouldRepaint(_painter(camera, raw: false)),
        isTrue,
      );
    });
  });
}
