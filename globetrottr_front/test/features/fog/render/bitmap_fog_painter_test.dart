import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_range.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BitmapFogPainter', () {
    test('without a source the whole screen is fog', () async {
      final alpha = await renderAlpha(painterFor(cameraAt()));

      expect(alpha(10, 10), closeTo(191, 1));
      expect(alpha(200, 400), closeTo(191, 1));
      expect(alpha(390, 790), closeTo(191, 1));
    });

    test(
      'a discovered disc is clear in the middle and foggy far away',
      () async {
        final store = await openStore();
        await store.applyPoint(
          sessionId: 'a',
          latitude: krakowLat,
          longitude: krakowLng,
        );
        await store.flush();
        final camera = cameraAt();
        final source = await readySource(store, camera);

        final alpha = await renderAlpha(painterFor(camera, source: source));

        expect(alpha(200, 400), 0);
        expect(alpha(215, 400), 0);
        expect(alpha(200, 370), 0);
        expect(alpha(200, 400 + 70), closeTo(191, 1));
        expect(alpha(20, 20), closeTo(191, 1));
        source.dispose();
        await store.dispose();
      },
    );

    test('the cleared disc matches the 30 m vision radius', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);
      final alpha = await renderAlpha(painterFor(camera, source: source));

      final east25 = offsetMeters(krakowLat, krakowLng, east: 25);
      final east36 = offsetMeters(krakowLat, krakowLng, east: 36);
      final inside = screenOf(camera, east25.lat, east25.lng);
      final outside = screenOf(camera, east36.lat, east36.lng);

      expect(alpha(inside.dx.round(), inside.dy.round()), lessThan(10));
      expect(alpha(outside.dx.round(), outside.dy.round()), greaterThan(180));
      source.dispose();
      await store.dispose();
    });

    test(
      'a rotated map still clears the disc where the camera projects it',
      () async {
        final store = await openStore();
        await store.applyPoint(
          sessionId: 'a',
          latitude: krakowLat,
          longitude: krakowLng,
        );
        await store.flush();
        final camera = cameraAt(rotation: 37);
        final source = await readySource(store, camera);
        final alpha = await renderAlpha(painterFor(camera, source: source));

        final near = offsetMeters(krakowLat, krakowLng, east: 20, north: 10);
        final far = offsetMeters(krakowLat, krakowLng, east: 70, north: -20);
        final nearAt = screenOf(camera, near.lat, near.lng);
        final farAt = screenOf(camera, far.lat, far.lng);

        expect(alpha(nearAt.dx.round(), nearAt.dy.round()), lessThan(10));
        expect(alpha(farAt.dx.round(), farAt.dy.round()), greaterThan(180));
        source.dispose();
        await store.dispose();
      },
    );

    test(
      'a strip crossing several tiles is continuous without seams',
      () async {
        final store = await openStore();
        await walk(store, 'a');
        await store.flush();
        final camera = cameraAt(
          lng: offsetMeters(krakowLat, krakowLng, east: 195).lng,
        );
        final source = await readySource(store, camera);
        final alpha = await renderAlpha(painterFor(camera, source: source));

        final start = screenOf(camera, krakowLat, krakowLng);
        final end = offsetMeters(krakowLat, krakowLng, east: 390);
        final stop = screenOf(camera, end.lat, end.lng);

        for (var dy = -25; dy <= 25; dy += 5) {
          for (var x = start.dx.round() + 3; x < stop.dx.round() - 3; x++) {
            if (x < 0 || x >= 400) continue;
            expect(
              alpha(x, start.dy.round() + dy),
              0,
              reason: 'x=$x dy=$dy',
            );
          }
        }
        source.dispose();
        await store.dispose();
      },
    );

    for (final rotation in [35.0, 90.0, 123.0, -17.0]) {
      test(
        'a rotated map ($rotation deg) shows no seams between tiles',
        () async {
          final store = await openStore();
          await walk(store, 'a', points: 80);
          await store.flush();
          final middle = offsetMeters(krakowLat, krakowLng, east: 395);
          final camera = cameraAt(
            lat: middle.lat,
            lng: middle.lng,
            rotation: rotation,
          );
          final source = await readySource(store, camera);
          final alpha = await renderAlpha(painterFor(camera, source: source));

          final end = offsetMeters(krakowLat, krakowLng, east: 790);
          final a = screenOf(camera, krakowLat, krakowLng);
          final b = screenOf(camera, end.lat, end.lng);
          final direction = (b - a) / (b - a).distance;
          final normal = Offset(-direction.dy, direction.dx);

          var checked = 0;
          var worst = 0;
          for (var t = 0.0; t <= (b - a).distance; t += 2) {
            for (var offset = -28.0; offset <= 28; offset += 4) {
              final p = a + direction * t + normal * offset;
              final x = p.dx.round();
              final y = p.dy.round();
              if (x < 0 || x >= 400 || y < 0 || y >= 800) continue;
              checked++;
              worst = worst < alpha(x, y) ? alpha(x, y) : worst;
            }
          }

          expect(checked, greaterThan(500));
          expect(worst, lessThan(4));
          source.dispose();
          await store.dispose();
        },
      );
    }

    test('the soft rim has no jump where tiles meet', () async {
      final store = await openStore();
      await walk(store, 'a');
      await store.flush();
      final camera = cameraAt(
        lng: offsetMeters(krakowLat, krakowLng, east: 195).lng,
      );
      final source = await readySource(store, camera);
      final alpha = await renderAlpha(painterFor(camera, source: source));
      final start = screenOf(camera, krakowLat, krakowLng);

      final rimY = start.dy.round() + 41;
      var worstStep = 0;
      for (var x = start.dx.round() + 10; x < 390; x++) {
        worstStep = worstStep < (alpha(x + 1, rimY) - alpha(x, rimY)).abs()
            ? (alpha(x + 1, rimY) - alpha(x, rimY)).abs()
            : worstStep;
      }

      expect(worstStep, lessThan(25));
      source.dispose();
      await store.dispose();
    });

    test('a vertical strip crossing tile rows has no seams either', () async {
      final store = await openStore();
      await walk(store, 'a', north: 1);
      await store.flush();
      final middle = offsetMeters(krakowLat, krakowLng, north: 195);
      final camera = cameraAt(lat: middle.lat);
      final source = await readySource(store, camera);
      final alpha = await renderAlpha(painterFor(camera, source: source));

      final top = offsetMeters(krakowLat, krakowLng, north: 380);
      final bottom = screenOf(camera, krakowLat, krakowLng);
      final upper = screenOf(camera, top.lat, top.lng);
      for (var y = upper.dy.round() + 3; y < bottom.dy.round() - 3; y++) {
        if (y < 0 || y >= 800) continue;
        expect(alpha(200, y), 0, reason: 'y=$y');
        expect(alpha(215, y), 0, reason: 'y=$y');
      }
      source.dispose();
      await store.dispose();
    });

    test('changing the zoom level does not make the fog jump', () async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final below = cameraAt(zoom: 16.49);
      final above = cameraAt(zoom: 16.51);
      final sourceBelow = await readySource(store, below);
      final sourceAbove = await readySource(store, above);
      expect(sourceBelow.levelFor(16.49), 16);
      expect(sourceAbove.levelFor(16.51), 17);

      final lower = await renderAlpha(painterFor(below, source: sourceBelow));
      final upper = await renderAlpha(painterFor(above, source: sourceAbove));

      final points = [
        offsetMeters(krakowLat, krakowLng, east: 100),
        offsetMeters(krakowLat, krakowLng, east: 100, north: 18),
        offsetMeters(krakowLat, krakowLng, east: 100, north: 60),
        offsetMeters(krakowLat, krakowLng, east: 100, north: -80),
      ];
      for (final p in points) {
        final a = screenOf(below, p.lat, p.lng);
        final b = screenOf(above, p.lat, p.lng);
        expect(
          (lower(a.dx.round(), a.dy.round()) -
                  upper(b.dx.round(), b.dy.round()))
              .abs(),
          lessThan(30),
        );
      }
      sourceBelow.dispose();
      sourceAbove.dispose();
      await store.dispose();
    });

    test(
      'draws the parent tile while the detailed tile is still loading',
      () async {
        final store = await openStore();
        await walk(store, 'a', points: 30);
        await store.flush();
        final coarse = cameraAt(zoom: 16);
        final fine = cameraAt();
        final source = FogTileSource(store);
        source.ensureRange(FogTileRange.visible(coarse, 16));
        await source.whenIdle();

        final alpha = await renderAlpha(painterFor(fine, source: source));

        expect(alpha(200, 400), lessThan(10));
        expect(alpha(20, 20), closeTo(191, 1));
        source.dispose();
        await store.dispose();
      },
    );

    test(
      'draws the child tiles while the coarser tile is still loading',
      () async {
        final store = await openStore();
        await walk(store, 'a', points: 30);
        await store.flush();
        final fine = cameraAt();
        final coarse = cameraAt(zoom: 16);
        final source = FogTileSource(store);
        source.ensureRange(FogTileRange.visible(fine, 17));
        await source.whenIdle();

        final alpha = await renderAlpha(painterFor(coarse, source: source));
        final inside = offsetMeters(krakowLat, krakowLng, east: 100);
        final at = screenOf(coarse, inside.lat, inside.lng);

        expect(alpha(at.dx.round(), at.dy.round()), lessThan(20));
        expect(alpha(20, 20), closeTo(191, 1));
        source.dispose();
        await store.dispose();
      },
    );

    test('the live disc clears the fog around the player at once', () async {
      final camera = cameraAt();

      final alpha = await renderAlpha(
        painterFor(camera, liveCenter: const LatLng(krakowLat, krakowLng)),
      );

      expect(alpha(200, 400), 0);
      expect(alpha(215, 400), lessThan(5));
      expect(alpha(200, 400 + 70), closeTo(191, 1));
    });

    test(
      'the soft edge option keeps the middle clear and the distance foggy',
      () async {
        final store = await openStore();
        await walk(store, 'a', points: 30);
        await store.flush();
        final camera = cameraAt();
        final source = await readySource(store, camera);

        final alpha = await renderAlpha(
          painterFor(camera, source: source, softEdge: true),
        );

        expect(alpha(250, 400), lessThan(5));
        expect(alpha(20, 20), closeTo(191, 2));
        source.dispose();
        await store.dispose();
      },
    );

    test('the soft edge turns the sharp rim into a gradient', () async {
      final store = await openStore();
      await walk(store, 'a', points: 30);
      await store.flush();
      final camera = cameraAt(zoom: 18.5);
      final source = await readySource(store, camera);
      final hard = await renderAlpha(painterFor(camera, source: source));
      final soft = await renderAlpha(
        painterFor(camera, source: source, softEdge: true),
      );
      final start = screenOf(camera, krakowLat, krakowLng);
      final x = start.dx.round() + 60;
      final rim = start.dy.round() + 155;

      int widthOfGradient(int Function(int, int) read) {
        var count = 0;
        for (var dy = -60; dy <= 60; dy++) {
          final value = read(x, rim + dy);
          if (value > 10 && value < 180) count++;
        }
        return count;
      }

      expect(
        widthOfGradient(soft),
        greaterThanOrEqualTo(widthOfGradient(hard)),
      );
      source.dispose();
      await store.dispose();
    });

    test('a thin trail is still visible on a country sized view', () async {
      final store = await openStore();
      await walk(store, 'a', points: 60, stepMeters: 20);
      await store.flush();
      final camera = cameraAt(zoom: 6);
      final source = await readySource(store, camera);

      final alpha = await renderAlpha(painterFor(camera, source: source));

      var strongest = 191;
      for (var dx = -3; dx <= 3; dx++) {
        for (var dy = -3; dy <= 3; dy++) {
          final value = alpha(200 + dx, 400 + dy);
          if (value < strongest) strongest = value;
        }
      }
      expect(strongest, lessThan(120));
      source.dispose();
      await store.dispose();
    });

    test('records how long painting takes', () async {
      final store = await openStore();
      final camera = cameraAt();
      final source = await readySource(store, camera);

      await renderAlpha(painterFor(camera, source: source));
      await renderAlpha(painterFor(camera, source: source));

      expect(source.stats.frames, 2);
      expect(source.stats.averageMillis, greaterThanOrEqualTo(0));
      source.dispose();
      await store.dispose();
    });

    test('repaints when the view, the player or the options change', () async {
      final camera = cameraAt();
      final base = painterFor(camera);

      expect(base.shouldRepaint(painterFor(camera)), isFalse);
      expect(base.shouldRepaint(painterFor(cameraAt(zoom: 16))), isTrue);
      expect(base.shouldRepaint(painterFor(cameraAt(rotation: 5))), isTrue);
      expect(
        base.shouldRepaint(
          painterFor(camera, liveCenter: const LatLng(krakowLat, krakowLng)),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          BitmapFogPainter(
            camera: camera,
            options: const FogRenderOptions(opacity: 0.5),
          ),
        ),
        isTrue,
      );
    });
  });
}
