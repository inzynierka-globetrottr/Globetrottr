import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/debug/format_bytes.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_levels.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_painter.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:latlong2/latlong.dart';

/// Measures the heatmap on the device: a rebuild of the whole track log, the
/// cost of every live point, a flush, building tile images and painting.
/// It works on [scratch], never on the user's heatmap, and clears it after.
Future<List<String>> runHeatmapBenchmark({
  required TrackLogStorage log,
  required FogTileStorage scratch,
  required LatLng around,
  int livePoints = 2000,
  void Function(String line)? onLine,
}) async {
  final lines = <String>[];
  void say(String line) {
    lines.add(line);
    onLine?.call(line);
  }

  try {
    await scratch.clear();
    final logPoints = await log.count();
    if (logPoints > 0) {
      final store = await HeatStore.open(scratch);
      final timer = Stopwatch()..start();
      await store.rebuildFrom(log);
      final millis = math.max(1, timer.elapsedMilliseconds);
      final stats = await scratch.stats();
      say(
        'Rebuild: $logPoints points in $millis ms '
        '(${(logPoints * 1000 / millis).round()} points/s), '
        '${stats.tileCount} tiles, ${formatBytes(stats.totalBytes)}, '
        'peak ${store.diagnostics.peakCachedTiles} tiles in memory',
      );
      await store.dispose();
      await scratch.clear();
    } else {
      say('Rebuild: skipped, the track log is empty');
    }

    final store = await HeatStore.open(
      scratch,
      flushDelay: const Duration(hours: 1),
    );
    final micros = <int>[];
    for (var i = 0; i < livePoints; i++) {
      // A walk of one fix every 5 m, there and back over the same street,
      // so half of the points meet pixels the session already counted.
      final step = i < livePoints ~/ 2 ? i : livePoints - i;
      final at = const Distance().offset(around, step * 5.0, 90);
      final timer = Stopwatch()..start();
      await store.applyPoint(
        sessionId: 'benchmark',
        latitude: at.latitude,
        longitude: at.longitude,
      );
      micros.add(timer.elapsedMicroseconds);
    }
    micros.sort();
    say(
      'Live point: median ${micros[micros.length ~/ 2]} us, '
      'p95 ${micros[(micros.length * 0.95).floor()]} us, '
      'max ${micros.last} us ($livePoints points)',
    );

    final flushTimer = Stopwatch()..start();
    await store.flush();
    say(
      'Flush: ${flushTimer.elapsedMilliseconds} ms '
      '(${store.diagnostics.lastFlushTiles} tiles with the pyramid)',
    );

    final camera = MapCamera(
      crs: const Epsg3857(),
      center: around,
      zoom: store.baseZoom.toDouble(),
      rotation: 0,
      nonRotatedSize: const math.Point<double>(400, 800),
    );
    final range = camera.visibleTiles(store.baseZoom);
    await store.prepare(range);
    final drawn = [for (final id in range.ids) ?store.peek(id)];
    // A live point rebuilds the image of the tile under the player, so this
    // runs on the UI thread once per fix. The first round warms up.
    const rounds = 10;
    final pixelTimer = Stopwatch();
    for (var round = 0; round <= rounds; round++) {
      if (round == 1) pixelTimer.start();
      for (final mask in drawn) {
        FogTilePixels.build(
          mask,
          neighbor: (_, _) => null,
          levels: HeatLevels.greys,
        );
      }
    }
    final builds = drawn.length * rounds;
    final pixelMicros = builds == 0
        ? 0
        : pixelTimer.elapsedMicroseconds ~/ builds;
    say('Tile image pixels: $pixelMicros us per tile ($builds builds)');

    final source = HeatTileSource(store, levels: HeatLevels.greys);
    source.ensureVisible(camera);
    await source.whenIdle();
    final painter = HeatmapPainter(
      camera: camera,
      cold: AppPalette.light.heatCold,
      hot: AppPalette.light.heatHot,
      source: source,
    );
    var paintMicros = 0;
    const warmUp = 3;
    const frames = 30;
    for (var i = 0; i < warmUp + frames; i++) {
      final recorder = ui.PictureRecorder();
      final timer = Stopwatch()..start();
      painter.paint(Canvas(recorder), const Size(400, 800));
      if (i >= warmUp) paintMicros += timer.elapsedMicroseconds;
      recorder.endRecording().dispose();
    }
    say(
      'Paint at zoom ${store.baseZoom}: '
      '${(paintMicros / frames / 1000).toStringAsFixed(3)} ms per frame '
      '(${source.imageCount} images)',
    );
    source.dispose();
    await store.dispose();
  } finally {
    await scratch.clear();
  }
  return lines;
}
