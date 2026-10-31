import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FogTileSource', () {
    test('picks the level from the zoom within the pyramid', () async {
      final store = await openStore();
      final source = FogTileSource(store);

      expect(source.levelFor(FogConfig.baseZoom - 0.6), FogConfig.baseZoom - 1);
      expect(source.levelFor(FogConfig.baseZoom - 0.4), FogConfig.baseZoom);
      expect(source.levelFor(FogConfig.baseZoom + 3.0), FogConfig.baseZoom);
      expect(source.levelFor(2), 4);
      source.dispose();
      await store.dispose();
    });

    test(
      'builds images for tiles with fog data and flags the empty ones',
      () async {
        final store = await openStore();
        await store.applyPoint(
          sessionId: 'a',
          latitude: krakowLat,
          longitude: krakowLng,
        );
        await store.flush();
        final camera = cameraAt();
        final source = FogTileSource(store);

        source.ensureVisible(camera);
        await source.whenIdle();

        final here = tileOf(krakowLat, krakowLng, FogConfig.baseZoom);
        expect(source.imageFor(here), isNotNull);
        final empty = FogTileId(FogConfig.baseZoom, here.x + 1, here.y + 1);
        expect(source.imageFor(empty), isNull);
        expect(source.isAbsent(empty), isTrue);
        source.dispose();
        await store.dispose();
      },
    );

    test('tells listeners when an image becomes ready', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final source = FogTileSource(store);
      var notifications = 0;
      source.addListener(() => notifications++);

      source.ensureVisible(cameraAt());
      await source.whenIdle();

      expect(notifications, greaterThan(0));
      source.dispose();
      await store.dispose();
    });

    test('refreshes an image when its tile changes', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);
      final before = source.imageFor(
        tileOf(krakowLat, krakowLng, FogConfig.baseZoom),
      );

      final east = offsetMeters(krakowLat, krakowLng, east: 40);
      await store.applyPoint(
        sessionId: 'a',
        latitude: east.lat,
        longitude: east.lng,
      );
      await store.flush();
      await pumpEventQueue();
      await source.whenIdle();

      final after = source.imageFor(
        tileOf(krakowLat, krakowLng, FogConfig.baseZoom),
      );
      expect(after, isNotNull);
      expect(identical(before, after), isFalse);
      source.dispose();
      await store.dispose();
    });

    test(
      'creates an image for a tile discovered in a previously empty area',
      () async {
        final store = await openStore();
        final camera = cameraAt();
        final source = await readySource(store, camera);
        final id = tileOf(krakowLat, krakowLng, FogConfig.baseZoom);
        expect(source.imageFor(id), isNull);

        await store.applyPoint(
          sessionId: 'a',
          latitude: krakowLat,
          longitude: krakowLng,
        );
        await store.flush();
        await pumpEventQueue();
        await source.whenIdle();

        expect(source.imageFor(id), isNotNull);
        source.dispose();
        await store.dispose();
      },
    );

    test('keeps no more images than its limit', () async {
      final store = await openStore();
      await walk(store, 'a', points: 150, stepMeters: 25);
      await store.flush();
      final source = FogTileSource(store, maxImages: 4);
      final camera = cameraAt();

      for (var i = 0; i < 6; i++) {
        final at = offsetMeters(krakowLat, krakowLng, east: i * 600.0);
        source.ensureVisible(cameraAt(lat: at.lat, lng: at.lng));
        await source.whenIdle();
      }

      expect(source.imageCount, lessThanOrEqualTo(9));
      expect(camera.zoom, FogConfig.baseZoom);
      source.dispose();
      await store.dispose();
    });

    test('drops every image when the fog is cleared', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);
      expect(source.imageCount, greaterThan(0));

      await store.clear();
      await pumpEventQueue();
      await source.whenIdle();

      expect(
        source.imageFor(tileOf(krakowLat, krakowLng, FogConfig.baseZoom)),
        isNull,
      );
      source.dispose();
      await store.dispose();
    });

    test('finds the nearest cached ancestor image', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final source = FogTileSource(store);
      source.ensureRange(FogTileRange.visible(cameraAt(zoom: 15), 15));
      await source.whenIdle();

      final fallback = source.fallbackFor(
        tileOf(krakowLat, krakowLng, FogConfig.baseZoom),
      );

      expect(fallback, isNotNull);
      expect(fallback!.id, tileOf(krakowLat, krakowLng, 15));
      source.dispose();
      await store.dispose();
    });

    test('an image still being built does not outlive a clear', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);
      final east = offsetMeters(krakowLat, krakowLng, east: 40);
      await store.applyPoint(
        sessionId: 'a',
        latitude: east.lat,
        longitude: east.lng,
      );

      await store.flush();
      await pumpEventQueue(times: 1);
      expect(source.pendingBuilds, greaterThan(0));
      await store.clear();
      await pumpEventQueue();
      await source.whenIdle();

      expect(
        source.imageFor(tileOf(krakowLat, krakowLng, FogConfig.baseZoom)),
        isNull,
      );
      source.dispose();
      await store.dispose();
    });

    test('a tile requested twice at once is built once', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final source = FogTileSource(store);
      var notifications = 0;
      source.addListener(() => notifications++);
      final nearby = offsetMeters(krakowLat, krakowLng, east: 800);

      source.ensureVisible(cameraAt());
      source.ensureVisible(cameraAt(lat: nearby.lat, lng: nearby.lng));
      await source.whenIdle();

      expect(notifications, 1);
      source.dispose();
      await store.dispose();
    });

    test('a change during a build reaches the image', () async {
      final store = await openStore();
      await store.applyPoint(
        sessionId: 'a',
        latitude: krakowLat,
        longitude: krakowLng,
      );
      await store.flush();
      final camera = cameraAt();
      final source = await readySource(store, camera);
      final first = offsetMeters(krakowLat, krakowLng, east: 40);
      final second = offsetMeters(krakowLat, krakowLng, east: 150);

      await store.applyPoint(
        sessionId: 'a',
        latitude: first.lat,
        longitude: first.lng,
      );
      await store.flush();
      await pumpEventQueue(times: 1);
      expect(source.pendingBuilds, greaterThan(0));
      await store.applyPoint(
        sessionId: 'a',
        latitude: second.lat,
        longitude: second.lng,
      );
      await store.flush();
      await pumpEventQueue();
      await source.whenIdle();
      await pumpEventQueue();

      expect(store.trail.segments, isEmpty);
      final spot = screenOf(camera, second.lat, second.lng);
      final alpha = await renderAlpha(painterFor(camera, source: source));
      expect(alpha(spot.dx.round(), spot.dy.round()), lessThan(10));
      source.dispose();
      await store.dispose();
    });

    test('whenIdle completes at once when nothing is loading', () async {
      final store = await openStore();
      final source = FogTileSource(store);

      await source.whenIdle();

      expect(source.pendingBuilds, 0);
      source.dispose();
      await store.dispose();
    });

    test('is safe to dispose while images are being built', () async {
      final store = await openStore();
      await walk(store, 'a', points: 20);
      await store.flush();
      final source = FogTileSource(store);

      source.ensureVisible(cameraAt());
      source.dispose();
      await pumpEventQueue();
      await store.dispose();
    });
  });
}
