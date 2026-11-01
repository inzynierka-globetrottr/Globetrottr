import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_layer.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

Future<int Function(int x, int y)> _capture(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage();
  final bytes = (await image.toByteData())!;
  // The map paints an opaque light grey (224) under the fog, so the fog
  // strength is read from how much that grey was darkened.
  return (int x, int y) {
    final red = bytes.getUint8((y * image.width + x) * 4);
    return ((224 - red) / 224 * 255).round();
  };
}

/// Lets the map lay out, the source load and decode tiles, and the layer
/// repaint, the way consecutive frames do in the app.
Future<void> _settle(WidgetTester tester, FogTileSource source) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
    await source.whenIdle();
  }
  await tester.pump();
}

Widget _app(GlobalKey key, MapController controller, FogTileSource? source) {
  return MaterialApp(
    home: Center(
      child: SizedBox(
        width: 400,
        height: 800,
        child: RepaintBoundary(
          key: key,
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: const LatLng(krakowLat, krakowLng),
              initialZoom: FogConfig.baseZoom.toDouble(),
            ),
            children: [BitmapFogLayer(source: source)],
          ),
        ),
      ),
    ),
  );
}

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('without a source the layer fogs the whole map', (tester) async {
    _phoneScreen(tester);
    await tester.runAsync(() async {
      final key = GlobalKey();
      await tester.pumpWidget(_app(key, MapController(), null));
      await tester.pump();

      final alpha = await _capture(key);

      expect(alpha(200, 400), closeTo(191, 1));
      expect(alpha(5, 5), closeTo(191, 1));
    });
  });

  testWidgets('clears discovered ground and follows the camera', (
    tester,
  ) async {
    _phoneScreen(tester);
    await tester.runAsync(() async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final source = FogTileSource(store);
      final key = GlobalKey();
      final controller = MapController();
      await tester.pumpWidget(_app(key, controller, source));
      await _settle(tester, source);

      final onTrail = await _capture(key);
      expect(onTrail(200, 400), lessThan(10));
      expect(onTrail(200, 400 + 120), closeTo(191, 1));

      final away = offsetMeters(krakowLat, krakowLng, north: 3000);
      controller.move(
        LatLng(away.lat, away.lng),
        FogConfig.baseZoom.toDouble(),
      );
      await tester.pump();
      await _settle(tester, source);

      final awayFromTrail = await _capture(key);
      expect(awayFromTrail(200, 400), closeTo(191, 1));

      controller.move(
        const LatLng(krakowLat, krakowLng),
        FogConfig.baseZoom.toDouble(),
      );
      await tester.pump();
      await _settle(tester, source);

      final back = await _capture(key);
      expect(back(200, 400), lessThan(10));
      source.dispose();
      await store.dispose();
    });
  });

  testWidgets('keeps the trail visible while zooming out and rotating', (
    tester,
  ) async {
    _phoneScreen(tester);
    await tester.runAsync(() async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final source = FogTileSource(store);
      final key = GlobalKey();
      final controller = MapController();
      await tester.pumpWidget(_app(key, controller, source));
      await _settle(tester, source);

      controller.moveAndRotate(const LatLng(krakowLat, krakowLng), 13, 40);
      await tester.pump();
      await _settle(tester, source);

      final alpha = await _capture(key);
      var strongest = 191;
      for (var dx = -6; dx <= 6; dx++) {
        for (var dy = -6; dy <= 6; dy++) {
          final value = alpha(200 + dx, 400 + dy);
          if (value < strongest) strongest = value;
        }
      }
      expect(strongest, lessThan(120));
      source.dispose();
      await store.dispose();
    });
  });
}
