import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_levels.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_style.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_painter.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';

typedef _Pixel = ({int r, int g, int b, int a});

const _cold = Color(0x80E3A33A);
const _hot = Color(0xF2D9531E);
const _style = HeatStyle(stops: [HeatStop(0, _cold), HeatStop(1, _hot)]);

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
    // As wide as the fog, so the edges match [baseRadiusPixels].
    radiusMeters: 50,
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
  final source = HeatTileSource(store, levels: _style.levels);
  source.ensureVisible(camera);
  await source.whenIdle();
  return (store, source);
}

void _expectColor(_Pixel pixel, Color color) {
  expect(pixel.a, closeTo(color.a * 255, 2));
  expect(pixel.r, closeTo(color.r * 255, 3));
  expect(pixel.g, closeTo(color.g * 255, 3));
  expect(pixel.b, closeTo(color.b * 255, 3));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('draws nothing where nobody went', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 1);

    final pixel = await _render(
      HeatmapPainter(camera: camera, style: _style, source: source),
    );

    expect(pixel(200, 400 + 80).a, 0);
    expect(pixel(10, 10).a, 0);
    source.dispose();
    await store.dispose();
  });

  test('a place visited once has the first colour of the scale', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 1);

    final pixel = await _render(
      HeatmapPainter(camera: camera, style: _style, source: source),
    );

    _expectColor(pixel(200, 400), _cold);
    source.dispose();
    await store.dispose();
  });

  test('the busiest places have the last colour of the scale', () async {
    final camera = cameraAt();
    final (store, source) = await _heatAt(camera, sessions: 60);

    final pixel = await _render(
      HeatmapPainter(camera: camera, style: _style, source: source),
    );

    _expectColor(pixel(200, 400), _hot);
    source.dispose();
    await store.dispose();
  });

  test('a backdrop covers the map even without data', () async {
    const style = HeatStyle(
      stops: [HeatStop(0, _cold), HeatStop(1, _hot)],
      backdrop: Color(0x80000000),
    );

    final pixel = await _render(
      HeatmapPainter(camera: cameraAt(), style: style),
    );

    expect(pixel(200, 400).a, closeTo(128, 1));
  });

  test(
    'the app look spreads a busy place into a patch past its edge',
    () async {
      final camera = cameraAt();
      final (store, _) = await _heatAt(camera, sessions: 60);
      final style = HeatStyle.of(AppPalette.light);
      final source = HeatTileSource(store)..useSpread(style.spread);
      source.ensureVisible(camera);
      await source.whenIdle();
      final edge = (baseRadiusPixels * 1.3).round();

      final pixel = await _render(
        HeatmapPainter(camera: camera, style: style, source: source),
      );
      final backdrop = (style.backdrop!.a * 255).round();

      expect(pixel(200, 400).a, greaterThan(backdrop));
      expect(pixel(200 + edge, 400).a, greaterThan(backdrop));
      expect(pixel(10, 10).a, closeTo(backdrop, 1));
      source.dispose();
      await store.dispose();
    },
  );

  group('HeatStyle', () {
    test('the app look darkens the map and shows density patches', () {
      const palette = AppPalette.light;
      final style = HeatStyle.of(palette);

      expect(style.backdrop, palette.heatBackdrop);
      expect(style.colorAt(0), palette.heatRare);
      expect(style.colorAt(1), palette.heatBusiest);
      expect(style.densityPixels, greaterThan(0));
      expect(style.spread, isNotNull);
      expect(identical(style.spread, HeatStyle.of(palette).spread), isTrue);
      expect(HeatStyle.of(palette), style);
    });

    test('runs through its stops along the scale', () {
      const style = HeatStyle(
        stops: [
          HeatStop(0, Color(0xFF000000)),
          HeatStop(0.5, Color(0xFFFF0000)),
          HeatStop(1, Color(0xFFFFFFFF)),
        ],
      );

      expect(style.colorAt(0), const Color(0xFF000000));
      expect(style.colorAt(0.5), const Color(0xFFFF0000));
      expect(style.colorAt(0.75).g, closeTo(0.5, 0.01));
      expect(style.colorAt(1), const Color(0xFFFFFFFF));
    });

    test('leaves untouched places transparent and is cached', () {
      expect(_style.levels[0], 0);
      expect(identical(_style.levels, _style.levels), isTrue);
      const same = HeatStyle(stops: [HeatStop(0, _cold), HeatStop(1, _hot)]);
      expect(identical(same.levels, _style.levels), isTrue);
    });
  });

  test('HeatLevels place counts on a logarithmic scale', () {
    expect(HeatLevels.shareOf(0), isNull);
    expect(HeatLevels.shareOf(1), 0);
    expect(HeatLevels.shareOf(5), greaterThan(HeatLevels.shareOf(2)!));
    expect(HeatLevels.shareOf(1000), 1);
  });
}
