import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

const _fogAlpha = 191;

Future<int> _alphaAt(
  FogTileSource source,
  double zoom,
  double east, {
  LatLng? head,
}) async {
  final camera = cameraAt(zoom: zoom);
  final at = offsetMeters(krakowLat, krakowLng, east: east);
  final spot = screenOf(camera, at.lat, at.lng);
  final alpha = await renderAlpha(
    painterFor(camera, source: source, head: head),
  );
  return alpha(spot.dx.round(), spot.dy.round());
}

LatLng _eastOfStart(double meters) {
  final at = offsetMeters(krakowLat, krakowLng, east: meters);
  return LatLng(at.lat, at.lng);
}

Future<void> _settle(FogTileSource source) async {
  await pumpEventQueue();
  await source.whenIdle();
  await pumpEventQueue();
}

List<int> _column(int Function(int, int) alpha) => [
  for (var y = 400; y < 800; y++) alpha(200, y),
];

/// Where the fog starts below the middle of the screen, at half strength.
double _edgeBelow(int Function(int, int) alpha) {
  const half = _fogAlpha / 2;
  for (var y = 400; y < 799; y++) {
    final a = alpha(205, y);
    final b = alpha(205, y + 1);
    if (a < half && b >= half) return y + (half - a) / (b - a);
  }
  return -1;
}

int _worst(List<int> a, List<int> b) {
  var worst = 0;
  for (var i = 0; i < a.length; i++) {
    worst = math.max(worst, (a[i] - b[i]).abs());
  }
  return worst;
}

/// Alpha along the middle column of the screen, through the lower edge of the
/// walk, without and with its tiles.
Future<(List<int>, List<int>)> _edgeBeforeAndAfter(
  MapCamera camera,
  int points,
) async {
  final store = await openStore();
  final source = await readySource(store, camera);
  await walk(store, 'a', points: points);
  final trail = _column(
    await renderAlpha(painterFor(camera, source: source, softEdge: true)),
  );
  await store.flush();
  await _settle(source);
  final tiles = _column(
    await renderAlpha(painterFor(camera, source: source, softEdge: true)),
  );
  source.dispose();
  await store.dispose();
  return (trail, tiles);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final zoom in [16.0, 14.6, 12.6]) {
    test('unflushed points show at zoom $zoom without any image', () async {
      final store = await openStore();
      final source = await readySource(store, cameraAt(zoom: zoom));

      await walk(store, 'a', points: 30);
      await _settle(source);

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
      final (trail, tiles) = await _edgeBeforeAndAfter(camera, 30);

      expect(_worst(trail, tiles), lessThan(24));
    });
  }

  test('on a rotated map the trail edge looks like the tile edge', () async {
    final camera = cameraAt(zoom: 17, rotation: 37);

    final (trail, tiles) = await _edgeBeforeAndAfter(camera, 30);

    expect(_worst(trail, tiles), lessThan(24));
  });

  for (final level in [14.5, 13.5, 12.5, 11.5]) {
    test('the fog edge stays put when the level changes at $level', () async {
      final store = await openStore();
      await walk(store, 'a', points: 60);
      await store.flush();
      Future<double> edgeAt(double zoom) async {
        final camera = cameraAt(zoom: zoom);
        final source = await readySource(store, camera);
        final alpha = await renderAlpha(
          painterFor(camera, source: source, softEdge: true),
        );
        source.dispose();
        return _edgeBelow(alpha);
      }

      final finer = await edgeAt(level + 0.01);
      final coarser = await edgeAt(level - 0.01);

      expect(finer - coarser, closeTo(0, 1));
      await store.dispose();
    });
  }

  for (final zoom in [16.0, 18.0]) {
    test('at zoom $zoom a lone point looks like its tile', () async {
      final (trail, tiles) = await _edgeBeforeAndAfter(cameraAt(zoom: zoom), 1);

      expect(_worst(trail, tiles), lessThan(24));
    });
  }

  test('the trail and its tiles do not add up where they overlap', () async {
    final camera = cameraAt(zoom: 17);
    final store = await openStore();
    final source = await readySource(store, camera);
    await walk(store, 'a', points: 30);
    final before = _column(
      await renderAlpha(painterFor(camera, source: source)),
    );

    final frames = <Future<int Function(int, int)>>[];
    source.addListener(() {
      frames.add(renderAlpha(painterFor(camera, source: source)));
    });
    await store.flush();
    await _settle(source);

    expect(frames, isNotEmpty);
    for (final frame in frames) {
      expect(_worst(before, _column(await frame)), lessThan(24));
    }
    source.dispose();
    await store.dispose();
  });

  test('a point is on the trail before anything is awaited', () async {
    final store = await openStore();

    final applied = store.applyPoint(
      sessionId: 'a',
      latitude: krakowLat,
      longitude: krakowLng,
    );

    expect(store.trail.segments, hasLength(1));
    await applied;
    await store.dispose();
  });

  test('a flush keeps the points not in the tiles yet', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 3);

    final flushed = store.flush();
    final later = _eastOfStart(30);
    final applied = store.applyPoint(
      sessionId: 'a',
      latitude: later.latitude,
      longitude: later.longitude,
    );
    await flushed;
    await _settle(source);

    expect(store.trail.segments, hasLength(1));
    await applied;
    source.dispose();
    await store.dispose();
  });

  test('a flush hands the trail over to the tiles', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 30);
    expect(store.trail.segments, isNotEmpty);

    await store.flush();
    await _settle(source);

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

  test('the player joins the last point at once', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 1);

    final alpha = await _alphaAt(source, 16, 100, head: _eastOfStart(200));

    expect(alpha, lessThan(10));
    source.dispose();
    await store.dispose();
  });

  test('the fog reaches the player and stops there', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt(zoom: 16));
    await walk(store, 'a', points: 1);
    final head = _eastOfStart(60);

    final inside = await _alphaAt(source, 16, 60 + 45, head: head);
    final outside = await _alphaAt(source, 16, 60 + 56, head: head);

    expect(inside, lessThan(10));
    expect(outside, _fogAlpha);
    source.dispose();
    await store.dispose();
  });

  test('a player beyond the limit is not joined', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt(zoom: 14.6));
    await walk(store, 'a', points: 1);

    final alpha = await _alphaAt(source, 14.6, 300, head: _eastOfStart(600));

    expect(alpha, _fogAlpha);
    source.dispose();
    await store.dispose();
  });

  test('a finished recording is not joined to the next one', () async {
    final store = await openStore();
    final source = await readySource(store, cameraAt());
    await walk(store, 'a', points: 1);

    store.endLivePath();
    final alpha = await _alphaAt(source, 16, 100, head: _eastOfStart(200));

    expect(alpha, _fogAlpha);
    source.dispose();
    await store.dispose();
  });

  test('the trail over known ground leaves with the next flush', () async {
    final store = await openStore();
    await walk(store, 'a', points: 5);
    await store.flush();

    await walk(store, 'b', points: 5);
    await store.flush();

    expect(store.trail.segments, isEmpty);
    await store.dispose();
  });

  test('a point over known ground needs no flush to leave', () async {
    final store = await openStore();
    await walk(store, 'a', points: 5);
    await store.flush();

    await walk(store, 'b', points: 5);
    unawaited(store.flush());
    await pumpEventQueue();

    expect(store.trail.segments, isEmpty);
    await store.dispose();
  });
}
