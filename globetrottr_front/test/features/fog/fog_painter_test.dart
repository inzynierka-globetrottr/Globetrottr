import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_track.dart';
import 'package:globetrottr_front/features/fog/fog_painter.dart';
import 'package:latlong2/latlong.dart';

const _viewSize = Size(400, 800);
const _center = LatLng(50.0614, 19.9383);

MapCamera _camera({double zoom = 16}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: _center,
    zoom: zoom,
    rotation: 0,
    nonRotatedSize: const math.Point<double>(400, 800),
  );
}

Future<int Function(int x, int y)> _renderAlpha(FogPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _viewSize);
  final image = await recorder.endRecording().toImage(400, 800);
  final bytes = (await image.toByteData())!;
  return (int x, int y) => bytes.getUint8((y * 400 + x) * 4 + 3);
}

void main() {
  group('thinScreenPoints', () {
    test('keeps first and last points of a sparse line', () {
      const points = [Offset.zero, Offset(10, 0), Offset(20, 0)];

      expect(thinScreenPoints(points), points);
    });

    test('drops intermediate points closer than the minimum spacing', () {
      const points = [
        Offset.zero,
        Offset(0.3, 0),
        Offset(0.6, 0),
        Offset(5, 0),
      ];

      expect(thinScreenPoints(points), const [Offset.zero, Offset(5, 0)]);
    });

    test('keeps the exact last point when it is close to the previous', () {
      const points = [Offset.zero, Offset(10, 0), Offset(10.4, 0)];

      expect(
        thinScreenPoints(points),
        const [Offset.zero, Offset(10.4, 0)],
      );
    });

    test('collapses points within one pixel into a single point', () {
      const points = [Offset(3, 3), Offset(3.2, 3), Offset(3.4, 3.1)];

      expect(thinScreenPoints(points), const [Offset(3, 3)]);
    });

    test('returns an empty list for no points', () {
      expect(thinScreenPoints(const []), isEmpty);
    });
  });

  group('FogPainter tracks', () {
    testWidgets('clears a continuous stadium between two distant points', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final track = FogTrack(
          sessionId: 'a',
          points: const [
            LatLng(50.0614, 19.9383),
            LatLng(50.0632, 19.9383),
          ],
        );
        final alpha = await _renderAlpha(
          FogPainter(
            holes: const [],
            camera: _camera(),
            holesRevision: 0,
            tracks: [track],
          ),
        );

        // 0.0018 deg of latitude is about 200 m, which is ~130 px at zoom 16.
        expect(alpha(200, 400), 0, reason: 'start point');
        expect(alpha(200, 335), 0, reason: 'midpoint of the segment');
        expect(alpha(208, 335), 0, reason: 'inside the strip');
        expect(alpha(200, 270), 0, reason: 'end point');
        expect(alpha(200, 262), 0, reason: 'inside the round end cap');
        expect(alpha(240, 335), greaterThan(150), reason: 'outside the strip');
        expect(alpha(200, 225), greaterThan(150), reason: 'beyond the cap');
        expect(alpha(20, 20), greaterThan(150), reason: 'far from the track');
      });
    });

    testWidgets('clears a circle for a single-point track', (tester) async {
      await tester.runAsync(() async {
        final track = FogTrack(sessionId: 'a', points: const [_center]);
        final alpha = await _renderAlpha(
          FogPainter(
            holes: const [],
            camera: _camera(),
            holesRevision: 0,
            tracks: [track],
          ),
        );

        expect(alpha(200, 400), 0);
        expect(alpha(210, 400), 0);
        expect(alpha(235, 400), greaterThan(150));
      });
    });

    testWidgets('never connects points from different tracks', (tester) async {
      await tester.runAsync(() async {
        final first = FogTrack(
          sessionId: 'a',
          points: const [LatLng(50.0614, 19.9383)],
        );
        final second = FogTrack(
          sessionId: 'b',
          points: const [LatLng(50.0632, 19.9383)],
        );
        final alpha = await _renderAlpha(
          FogPainter(
            holes: const [],
            camera: _camera(),
            holesRevision: 0,
            tracks: [first, second],
          ),
        );

        expect(alpha(200, 400), 0);
        expect(alpha(200, 270), 0);
        expect(alpha(200, 335), greaterThan(150));
      });
    });

    testWidgets('skips tracks that are outside of the viewport', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final far = FogTrack(
          sessionId: 'a',
          points: const [LatLng(10, 10), LatLng(10.001, 10)],
        );
        final alpha = await _renderAlpha(
          FogPainter(
            holes: const [],
            camera: _camera(),
            holesRevision: 0,
            tracks: [far],
          ),
        );

        expect(alpha(200, 400), greaterThan(150));
      });
    });

    test('repaints when the tracks list changes', () {
      final track = FogTrack(sessionId: 'a', points: const [_center]);
      final camera = _camera();
      final before = FogPainter(
        holes: const [],
        camera: camera,
        holesRevision: 0,
        tracks: [track],
      );
      final after = FogPainter(
        holes: const [],
        camera: camera,
        holesRevision: 0,
        tracks: [track.append(const LatLng(50.0615, 19.9384))],
      );

      expect(after.shouldRepaint(before), isTrue);
      expect(before.shouldRepaint(before), isFalse);
    });
  });
}
