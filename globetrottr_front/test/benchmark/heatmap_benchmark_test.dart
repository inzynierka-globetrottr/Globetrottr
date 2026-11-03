// Run with: FOG_BENCH=1 flutter test test/benchmark/heatmap_benchmark_test.dart
// Optional: FOG_BENCH_KM=2000 sets the length of the explorer journey. The
// same benchmark runs on a phone from the developer options.
@Timeout(Duration(minutes: 45))
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/heatmap_benchmark.dart';
import 'package:latlong2/latlong.dart';

import '../support/explorer_route_generator.dart';
import '../support/fog_test_helpers.dart';
import '../support/in_memory_fog_tile_storage.dart';
import '../support/in_memory_track_log_storage.dart';

final bool _enabled = Platform.environment['FOG_BENCH'] == '1';
final double _journeyKm =
    double.tryParse(Platform.environment['FOG_BENCH_KM'] ?? '') ?? 200;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('heatmap: rebuild, live points, flush and paint', () async {
    const start = LatLng(krakowLat, krakowLng);
    final log = InMemoryTrackLogStorage();
    await log.appendAll(
      ExplorerRouteGenerator.generate(start: start, totalKm: _journeyKm),
    );

    final lines = await runHeatmapBenchmark(
      log: log,
      scratch: InMemoryFogTileStorage(),
      around: start,
      onLine: (line) => debugPrint('BENCH heatmap $line'),
    );

    expect(lines, isNotEmpty);
  }, skip: !_enabled);
}
