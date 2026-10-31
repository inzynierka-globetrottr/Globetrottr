import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/recorded_points_source.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';

import '../support/fog_render_helpers.dart';
import '../support/fog_test_helpers.dart';
import '../support/in_memory_track_log_storage.dart';

/// Strongest alpha in the 7x7 pixels around where [camera] puts a point.
int _alphaAt(
  int Function(int x, int y) alpha,
  MapCamera camera,
  ({double lat, double lng}) at,
) {
  final p = screenOf(camera, at.lat, at.lng);
  var strongest = 0;
  for (var dx = -3; dx <= 3; dx++) {
    for (var dy = -3; dy <= 3; dy++) {
      final x = p.dx.round() + dx;
      final y = p.dy.round() + dy;
      if (x < 0 || x >= 400 || y < 0 || y >= 800) continue;
      strongest = math.max(strongest, alpha(x, y));
    }
  }
  return strongest;
}

Future<(RecordedPointsSource, MapCamera)> _loaded(
  InMemoryTrackLogStorage log, {
  double zoom = 17,
  double rotation = 0,
}) async {
  final camera = cameraAt(
    zoom: zoom,
    rotation: rotation,
    lng: offsetMeters(krakowLat, krakowLng, east: 100).lng,
  );
  final source = RecordedPointsSource(log);
  await source.ensure(camera);
  return (source, camera);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordedPointsPainter', () {
    test('draws nothing without points', () async {
      final camera = cameraAt();
      final source = RecordedPointsSource(InMemoryTrackLogStorage());

      final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

      for (var y = 0; y < 800; y += 20) {
        expect(alpha(200, y), 0);
      }
      source.dispose();
    });

    test('draws a dot on every recorded point', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a'));
      final (source, camera) = await _loaded(log);

      final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

      for (var i = 0; i < 20; i++) {
        expect(
          _alphaAt(
            alpha,
            camera,
            offsetMeters(krakowLat, krakowLng, east: i * 10.0),
          ),
          greaterThan(200),
          reason: 'point $i',
        );
      }
      source.dispose();
    });

    test(
      'draws a thinner line between consecutive points of a session',
      () async {
        final log = InMemoryTrackLogStorage();
        await log.appendAll(walkEast('a', points: 3, stepMeters: 60));
        final (source, camera) = await _loaded(log);

        final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

        final middle = offsetMeters(krakowLat, krakowLng, east: 30);
        final at = screenOf(camera, middle.lat, middle.lng);
        expect(alpha(at.dx.round(), at.dy.round()), greaterThan(60));
        final beside = alpha(at.dx.round(), at.dy.round() + 12);
        expect(beside, 0);
        source.dispose();
      },
    );

    test(
      'does not connect points that are not neighbours in the log',
      () async {
        final log = InMemoryTrackLogStorage();
        await log.append(logEntry('a', 0, offsetMeters(krakowLat, krakowLng)));
        await log.append(
          logEntry('a', 1, offsetMeters(krakowLat, krakowLng, north: 3000)),
        );
        await log.append(
          logEntry('a', 2, offsetMeters(krakowLat, krakowLng, east: 60)),
        );
        final (source, camera) = await _loaded(log);

        final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

        final middle = offsetMeters(krakowLat, krakowLng, east: 30);
        final at = screenOf(camera, middle.lat, middle.lng);
        expect(alpha(at.dx.round(), at.dy.round()), 0);
        source.dispose();
      },
    );

    test('does not connect different sessions', () async {
      final log = InMemoryTrackLogStorage();
      await log.append(logEntry('a', 0, offsetMeters(krakowLat, krakowLng)));
      await log.append(
        logEntry('b', 1, offsetMeters(krakowLat, krakowLng, east: 60)),
      );
      final (source, camera) = await _loaded(log);

      final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

      final middle = offsetMeters(krakowLat, krakowLng, east: 30);
      final at = screenOf(camera, middle.lat, middle.lng);
      expect(alpha(at.dx.round(), at.dy.round()), 0);
      source.dispose();
    });

    test('keeps the dots on their points when the map is rotated', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a', points: 12));
      final (source, camera) = await _loaded(log, rotation: 41);

      final alpha = await renderAlpha(RecordedPointsPainter(camera, source));

      expect(
        _alphaAt(alpha, camera, offsetMeters(krakowLat, krakowLng, east: 50)),
        greaterThan(200),
      );
      source.dispose();
    });

    test('survives a broken camera', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a', points: 5));
      final (source, _) = await _loaded(log);

      final alpha = await renderAlpha(
        RecordedPointsPainter(cameraAt(zoom: double.nan), source),
      );

      expect(alpha(200, 400), 0);
      source.dispose();
    });

    test('repaints when the points change', () async {
      final log = InMemoryTrackLogStorage();
      final (source, camera) = await _loaded(log);
      final painter = RecordedPointsPainter(camera, source);

      expect(
        painter.shouldRepaint(RecordedPointsPainter(camera, source)),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          RecordedPointsPainter(cameraAt(zoom: 16), source),
        ),
        isTrue,
      );
      source.dispose();
    });
  });
}
