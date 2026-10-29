// Run with: FOG_BENCH=1 flutter test test/benchmark/fog_benchmark_test.dart
// Optional: FOG_BENCH_KM=2000 sets the length of the explorer journey.
@Timeout(Duration(minutes: 45))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/data/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/sqflite_track_log_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../support/fog_render_helpers.dart';

final bool _enabled = Platform.environment['FOG_BENCH'] == '1';
final double _journeyKm =
    double.tryParse(Platform.environment['FOG_BENCH_KM'] ?? '') ?? 200;

void _say(String line) => debugPrint('BENCH $line');

double _paintMillis(
  BitmapFogPainter painter,
  int runs,
) {
  var total = 0;
  for (var i = 0; i < runs; i++) {
    final recorder = ui.PictureRecorder();
    final timer = Stopwatch()..start();
    painter.paint(Canvas(recorder), viewSize);
    total += timer.elapsedMicroseconds;
    recorder.endRecording().dispose();
  }
  return total / runs / 1000.0;
}

Future<void> _paintTable(
  String label,
  FogStore store,
  LatLng center,
  List<double> zooms,
) async {
  for (final zoom in zooms) {
    final camera = cameraAt(
      zoom: zoom,
      lat: center.latitude,
      lng: center.longitude,
    );
    final source = FogTileSource(store);
    source.ensureVisible(camera);
    await source.whenIdle();
    final painter = BitmapFogPainter(
      camera: camera,
      source: source,
      options: BitmapFogPainter.defaultOptions.copyWith(softEdge: false),
    );
    _paintMillis(painter, 3);
    final plain = _paintMillis(painter, 30);
    final soft = _paintMillis(
      BitmapFogPainter(camera: camera, source: source),
      30,
    );
    final tiles = FogTileRange.visible(camera, source.levelFor(zoom)).cellCount;
    _say(
      '$label zoom ${zoom.toStringAsFixed(1).padLeft(4)}: '
      'paint ${plain.toStringAsFixed(3)} ms '
      '(soft edge ${soft.toStringAsFixed(3)} ms), '
      'tiles in view $tiles, images ${source.imageCount}',
    );
    source.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fog benchmark', skip: _enabled ? false : 'set FOG_BENCH=1', () {
    test('P2: cost of one live GPS point', () async {
      final store = await openStore();
      const start = LatLng(50.0614, 19.9383);
      final points = ExplorerRouteGenerator.generate(start: start, totalKm: 40);
      for (final e in points.take(500)) {
        await store.applyPoint(
          sessionId: e.sessionId,
          latitude: e.latitude,
          longitude: e.longitude,
        );
      }
      final timer = Stopwatch()..start();
      var applied = 0;
      for (final e in points.skip(500).take(3000)) {
        await store.applyPoint(
          sessionId: e.sessionId,
          latitude: e.latitude,
          longitude: e.longitude,
        );
        applied++;
      }
      timer.stop();
      _say(
        'P2 live apply (incl. periodic flush): '
        '${(timer.elapsedMicroseconds / applied).toStringAsFixed(0)} us/point '
        'over $applied points',
      );
      await store.dispose();
    });

    test('P6 + comparison data: 50k explorer points', () async {
      const center = LatLng(50.0614, 19.9383);
      final entries = ExplorerRouteGenerator.generate(
        start: center,
        totalKm: 500,
      );
      final storage = InMemoryFogTileStorage();
      final store = await openStore(storage: storage);

      final timer = Stopwatch()..start();
      await store.importEntries(entries);
      await store.flush();
      timer.stop();
      final stats = await storage.stats();
      _say(
        'P6 import 50000 points through an isolate: '
        '${timer.elapsedMilliseconds} ms, '
        'tiles ${stats.tileCount}, payload ${stats.totalBytes} bytes, '
        'area ${(store.totalAreaM2 / 1e6).toStringAsFixed(4)} km2',
      );

      await _paintTable('50k walk', store, center, [12, 14, 16]);
      await store.dispose();
    });

    test('P1/P3/P4/P5/P7: explorer journey', () async {
      const start = LatLng(50.0614, 19.9383);
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: _journeyKm,
      );
      final storage = InMemoryFogTileStorage();
      final store = await openStore(storage: storage);

      final timer = Stopwatch()..start();
      await store.importEntries(entries, chunkSize: 4000);
      await store.flush();
      timer.stop();

      final stats = await storage.stats();
      final baseTiles = stats.tilesPerLevel[FogConfig.baseZoom] ?? 0;
      final flagOnly = (await storage.changedSince(
        0,
        limit: 1 << 30,
      )).where((t) => t.id.z == FogConfig.baseZoom && t.bytes == null).length;
      final payloadTiles = baseTiles - flagOnly;
      var baseBytes = 0;
      for (final tile in await storage.changedSince(0, limit: 1 << 30)) {
        if (tile.id.z == FogConfig.baseZoom)
          baseBytes += tile.bytes?.length ?? 0;
      }
      _say(
        'P3 journey ${_journeyKm.round()} km, ${entries.length} points imported in '
        '${timer.elapsed.inSeconds} s',
      );
      _say(
        'P3 tiles ${stats.tileCount} (base $baseTiles, of which full $flagOnly), '
        'payload total ${(stats.totalBytes / 1048576).toStringAsFixed(1)} MB, '
        'base ${(baseBytes / 1048576).toStringAsFixed(1)} MB, '
        'avg ${payloadTiles == 0 ? 0 : (baseBytes / payloadTiles).round()} B per base tile',
      );
      _say(
        'P3 discovered ${(store.totalAreaM2 / 1e6).toStringAsFixed(1)} km2, '
        'per level: ${stats.tilesPerLevel}',
      );
      await store.dispose();

      final middle = entries[entries.length ~/ 2];
      final center = LatLng(middle.latitude, middle.longitude);

      final coldTimer = Stopwatch()..start();
      final cold = await openStore(storage: storage);
      final coldSource = FogTileSource(cold);
      coldSource.ensureVisible(
        cameraAt(zoom: 16, lat: center.latitude, lng: center.longitude),
      );
      await coldSource.whenIdle();
      coldTimer.stop();
      _say(
        'P4 cold start to first ready frame (zoom 16): '
        '${coldTimer.elapsedMilliseconds} ms, cached tiles '
        '${cold.diagnostics.cachedTiles}',
      );
      coldSource.dispose();

      await _paintTable('journey', cold, center, [
        3,
        4,
        5,
        5.7,
        6,
        8,
        10,
        12,
        14,
        16,
        17,
        18,
        20,
      ]);
      _say(
        'P5 cached masks ${cold.diagnostics.cachedTiles} x ${FogMask.pixels ~/ 1024} KB = '
        '${(cold.diagnostics.cachedTiles * FogMask.pixels / 1048576).toStringAsFixed(1)} MB',
      );
      await cold.dispose();
    });

    test('track log: size, writing, listing and reading', () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dir = await Directory.systemTemp.createTemp('bench_tracks');
      addTearDown(() => dir.delete(recursive: true));
      const start = LatLng(50.0614, 19.9383);
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: _journeyKm,
      );
      final log = SqfliteTrackLogStorage(path: '${dir.path}/tracks.db');

      final timer = Stopwatch()..start();
      for (var i = 0; i < entries.length; i += 20000) {
        await log.appendAll(
          entries.sublist(i, (i + 20000).clamp(0, entries.length)),
        );
      }
      await log.compact();
      final writeMs = timer.elapsedMilliseconds;
      final bytes = await log.fileBytes();
      _say(
        'TRACKS ${entries.length} points: ${(bytes / 1048576).toStringAsFixed(2)} MB '
        '(${(bytes / entries.length).toStringAsFixed(1)} B/point), written in $writeMs ms',
      );

      timer
        ..reset()
        ..start();
      final sessions = await log.sessionSummaries();
      _say(
        'TRACKS list of ${sessions.length} trips: ${timer.elapsedMicroseconds} us',
      );

      timer
        ..reset()
        ..start();
      var read = 0;
      var after = 0;
      while (true) {
        final batch = await log.entriesAfter(after);
        if (batch.isEmpty) break;
        read += batch.length;
        after = batch.last.id!;
      }
      _say(
        'TRACKS read all $read points in ${timer.elapsedMilliseconds} ms '
        '(batches of 5000)',
      );

      final middle = entries[entries.length ~/ 2];
      timer
        ..reset()
        ..start();
      final inView = await log.entriesInBounds(
        south: middle.latitude - 0.004,
        west: middle.longitude - 0.006,
        north: middle.latitude + 0.004,
        east: middle.longitude + 0.006,
      );
      _say(
        'TRACKS ${inView.length} points of one map view in '
        '${timer.elapsedMilliseconds} ms',
      );

      timer
        ..reset()
        ..start();
      final live = SqfliteTrackLogStorage(path: '${dir.path}/live.db');
      for (final e in entries.take(2000)) {
        await live.append(e);
      }
      _say(
        'TRACKS live append: ${timer.elapsedMicroseconds ~/ 2000} us/point',
      );
      await live.close();
      await log.close();
    });

    test('P3 detail: zoom 16 / 17 / 18 storage and speed', () async {
      const start = LatLng(50.0614, 19.9383);
      final entries = ExplorerRouteGenerator.generate(
        start: start,
        totalKm: 60,
      );
      for (final zoom in [16, 17, 18]) {
        final storage = InMemoryFogTileStorage();
        final store = await FogStore.open(
          storage,
          baseZoom: zoom,
          flushDelay: const Duration(hours: 1),
        );
        final timer = Stopwatch()..start();
        await store.importEntries(
          List<TrackLogEntry>.of(entries),
          chunkSize: 4000,
        );
        await store.flush();
        timer.stop();
        final stats = await storage.stats();
        _say(
          'base zoom $zoom: 60 km imported in ${timer.elapsedMilliseconds} ms, '
          'base tiles ${stats.tilesPerLevel[zoom]}, '
          'payload ${(stats.totalBytes / 1024).toStringAsFixed(0)} KB, '
          'area ${(store.totalAreaM2 / 1e6).toStringAsFixed(3)} km2',
        );
        await store.dispose();
      }
    });
  });
}
