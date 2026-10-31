import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

const _fogAlpha = 191;

Future<int> _alphaAt(
  FogTileSource source,
  double zoom,
  double east, {
  LatLng? liveCenter,
}) async {
  final camera = cameraAt(zoom: zoom);
  final at = offsetMeters(krakowLat, krakowLng, east: east);
  final spot = screenOf(camera, at.lat, at.lng);
  final alpha = await renderAlpha(
    painterFor(camera, source: source, liveCenter: liveCenter),
  );
  return alpha(spot.dx.round(), spot.dy.round());
}

LatLng _eastOfStart(double meters) {
  final at = offsetMeters(krakowLat, krakowLng, east: meters);
  return LatLng(at.lat, at.lng);
}

/// Alpha along the middle column of the screen, downwards from the walk
/// through its lower edge.
Future<List<int>> _edgeProfile(
  MapCamera camera, {
  required bool flushed,
}) async {
  final store = await openStore();
  final source = await readySource(store, camera);
  await walk(store, 'a', points: 30);
  if (flushed) {
    await store.flush();
    await pumpEventQueue();
    await source.whenIdle();
    await pumpEventQueue();
  }
  final alpha = await renderAlpha(painterFor(camera, source: source));
  final profile = [for (var y = 400; y < 800; y++) alpha(200, y)];
  source.dispose();
  await store.dispose();
  return profile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final zoom in [16.0, 14.6, 12.6]) {
    test('unflushed points show at zoom $zoom without any image', () async {
      final store = await openStore();
      final source = await readySource(store, cameraAt(zoom: zoom));

      await walk(store, 'a', points: 30);
      await pumpEventQueue();
      await source.whenIdle();

      expect(source.imageCount, 0);
      expect(await _alphaAt(source, zoom, 150), lessThan(60));
      expect(await _alphaAt(source, zoom, -200), _fogAlpha);
      source.dispose();
      await store.dispose();
    });
  }

  for (final zoom in [14.6, 15.0, 16.0, 17.0, 18.0, 19.0]) {
    test('at zoom $zoom the trail edge looks like the tile edge', () async {
      final camera = cameraAt(
        zoom: zoom,
        lng: offsetMeters(krakowLat, krakowLng, east: 145).lng,
      );
      final trail = await _edgeProfile(camera, flushed: false);
      final tiles = await _edgeProfile(camera, flushed: true);

      var worst = 0;
      for (var i = 0; i < tiles.length; i++) {
        worst = math.max(worst, (trail[i] - tiles[i]).abs());
      }
      expect(worst, lessThan(32));
    });
  }

  test('a flush shows its images together with dropping the trail', () async {
    const z = FogConfig.baseZoom;
    final border = (tileOf(krakowLat, krakowLng, z).x + 1) * FogTileId.size;
    final start = FogMercator.xToLng(border * 1.0 - 40, z);
    final store = await openStore();
    final source = await readySource(
      store,
      cameraAt(lng: start, zoom: FogConfig.baseZoom + 0.0),
    );
    await walk(store, 'a', points: 30, startLng: start);

    final overlaps = <bool>[];
    source.addListener(() {
      overlaps.add(source.imageCount > 0 && store.trail.segments.isNotEmpty);
    });
    await store.flush();
    await pumpEventQueue();
    await source.whenIdle();
    await pumpEventQueue();

    expect(source.imageCount, greaterThan(1));
    expect(overlaps, isNotEmpty);
    expect(overlaps, everyElement(isFalse));
    source.dispose();
    await store.dispose();
  });

  test('a flush hands the trail over to the tiles', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 30);
    expect(store.trail.segments, isNotEmpty);

    await store.flush();
    await pumpEventQueue();
    await source.whenIdle();
    await pumpEventQueue();

    expect(store.trail.segments, isEmpty);
    expect(source.imageCount, greaterThan(0));
    expect(await _alphaAt(source, 16, 150), lessThan(10));
    source.dispose();
    await store.dispose();
  });

  test('the trail stays until the images of a flush are ready', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 30);

    await store.flush();

    expect(store.trail.segments, isNotEmpty);
    source.dispose();
    await store.dispose();
  });

  test('without a listener a flush forgets the trail by itself', () async {
    final store = await openStore();
    await walk(store, 'a', points: 30);

    await store.flush();

    expect(store.trail.segments, isEmpty);
    await store.dispose();
  });

  test('a gap over the limit stays fogged in the trail', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt(zoom: 14.6));
    final far = _eastOfStart(600);

    await walk(store, 'a', points: 1);
    await store.applyPoint(
      sessionId: 'a',
      latitude: far.latitude,
      longitude: far.longitude,
    );
    await pumpEventQueue();

    expect(await _alphaAt(source, 14.6, 300), _fogAlpha);
    expect(await _alphaAt(source, 14.6, 600), lessThan(60));
    source.dispose();
    await store.dispose();
  });

  test('the live position joins the last point at once', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 1);

    final alpha = await _alphaAt(
      source,
      16,
      100,
      liveCenter: _eastOfStart(200),
    );

    expect(alpha, lessThan(10));
    source.dispose();
    await store.dispose();
  });

  test('a live position beyond the limit is not joined', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt(zoom: 14.6));
    await walk(store, 'a', points: 1);

    final alpha = await _alphaAt(
      source,
      14.6,
      300,
      liveCenter: _eastOfStart(600),
    );

    expect(alpha, _fogAlpha);
    source.dispose();
    await store.dispose();
  });

  test('a finished recording is not joined to the next one', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 1);

    store.endLivePath();
    final alpha = await _alphaAt(
      source,
      16,
      100,
      liveCenter: _eastOfStart(200),
    );

    expect(alpha, _fogAlpha);
    source.dispose();
    await store.dispose();
  });

  test('a pass over known ground adds nothing to the trail', () async {
    final store = await openStore();
    await walk(store, 'a', points: 5);
    await store.flush();

    await walk(store, 'b', points: 5);

    expect(store.trail.segments, isEmpty);
    await store.dispose();
  });
}
