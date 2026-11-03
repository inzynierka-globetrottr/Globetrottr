import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_levels.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_painter.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';

typedef _Pixel = ({int r, int g, int b, int a});

Future<_Pixel Function(int x, int y)> _render(HeatmapPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), viewSize);
  final image = await recorder.endRecording().toImage(400, 800);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  return (int x, int y) {
    final i = (y * 400 + x) * 4;
    return (
      r: bytes.getUint8(i),
      g: bytes.getUint8(i + 1),
      b: bytes.getUint8(i + 2),
      a: bytes.getUint8(i + 3),
    );
  };
}

Future<(HeatStore, HeatTileSource)> _heatAt(
  MapCamera camera, {
  required int sessions,
}) async {
  final store = await HeatStore.open(
    InMemoryFogTileStorage(),
    encodeInIsolate: false,
    flushDelay: const Duration(hours: 1),
  );
  for (var s = 0; s < sessions; s++) {
    await store.applyPoint(
      sessionId: 'session $s',
      latitude: krakowLat,
      longitude: krakowLng,
    );
  }
  await store.flush();
  final source = HeatTileSource(store, levels: HeatLevels.greys);
  source.ensureVisible(camera);
  await source.whenIdle();
  return (store, source);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const palette = AppPalette.light;

  HeatmapPainter painter(MapCamera camera, HeatTileSource? source) {
    return HeatmapPainter(
      camera: camera,
      cold: palette.heatCold,
      hot: palette.heatHot,
      source: source,
    );
  }

  test('draws nothing where nobody went', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 1);

    final pixel = await _render(painter(camera, source));

    expect(pixel(200, 400 + 80).a, 0);
    expect(pixel(10, 10).a, 0);
    source.dispose();
    await store.dispose();
  });

  test('a place visited once is faint and in the cold colour', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 1);

    final centre = (await _render(painter(camera, source)))(200, 400);

    final expectedAlpha = palette.heatHot.a * HeatLevels.first;
    expect(centre.a, closeTo(expectedAlpha, 2));
    expect(centre.r, closeTo(palette.heatCold.r * 255, 2));
    expect(centre.g, closeTo(palette.heatCold.g * 255, 2));
    expect(centre.b, closeTo(palette.heatCold.b * 255, 2));
    source.dispose();
    await store.dispose();
  });

  test('the busiest places reach the hot colour', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 60);

    final centre = (await _render(painter(camera, source)))(200, 400);

    expect(centre.a, closeTo(palette.heatHot.a * 255, 2));
    expect(centre.r, closeTo(palette.heatHot.r * 255, 2));
    expect(centre.g, closeTo(palette.heatHot.g * 255, 2));
    expect(centre.b, closeTo(palette.heatHot.b * 255, 2));
    source.dispose();
    await store.dispose();
  });

  test('without a source nothing is drawn', () async {
    final pixel = await _render(painter(cameraAt(), null));

    expect(pixel(200, 400).a, 0);
  });

  test('HeatLevels grow with the number of sessions', () {
    expect(HeatLevels.brightnessOf(0), 0);
    expect(HeatLevels.brightnessOf(1), HeatLevels.first);
    expect(
      HeatLevels.brightnessOf(5),
      greaterThan(HeatLevels.brightnessOf(2)),
    );
    expect(HeatLevels.brightnessOf(1000), 255);
  });
}
