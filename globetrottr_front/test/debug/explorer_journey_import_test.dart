import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_journey_import.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

const _krakow = LatLng(50.0614, 19.9383);

void main() {
  group('importJourney', () {
    test('imports the whole journey in chunks of limited size', () async {
      final chunks = <List<TrackLogEntry>>[];
      final expected = ExplorerRouteGenerator.generate(
        start: _krakow,
        totalKm: 30,
      );

      final result = await importJourney(
        ExplorerJourney(start: _krakow, totalKm: 30),
        importChunk: (chunk) async => chunks.add(chunk),
        chunkPoints: 1000,
      );

      expect(chunks.length, greaterThan(2));
      expect(chunks.every((c) => c.length <= 1000), isTrue);
      expect(chunks.expand((c) => c).length, expected.length);
      expect(result.points, expected.length);
      expect(result.km, closeTo(30, 0.1));
      expect(result.cancelled, isFalse);
    });

    test('reports the progress growing up to one', () async {
      final progress = <double>[];

      await importJourney(
        ExplorerJourney(start: _krakow, totalKm: 20),
        importChunk: (_) async {},
        chunkPoints: 300,
        onProgress: progress.add,
      );

      expect(progress, isNotEmpty);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
      expect(progress.last, 1);
    });

    test('stops after the current chunk once cancelled', () async {
      var imported = 0;
      var stop = false;

      final result = await importJourney(
        ExplorerJourney(start: _krakow, totalKm: 100000),
        importChunk: (chunk) async {
          imported++;
          if (imported == 3) stop = true;
        },
        chunkPoints: 500,
        isCancelled: () => stop,
      );

      expect(imported, 3);
      expect(result.cancelled, isTrue);
      expect(result.points, 1500);
    });
  });
}
