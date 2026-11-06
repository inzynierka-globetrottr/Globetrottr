import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import '../../../support/fog_render_helpers.dart';
import '../../../support/fog_test_helpers.dart';

FogCamera _camera({
  LatLng center = const LatLng(krakowLat, krakowLng),
  double zoom = 17,
  double rotation = 0,
  Size size = viewSize,
}) {
  return FogCamera(center: center, zoom: zoom, rotation: rotation, size: size);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final broken = <String, FogCamera>{
    'NaN latitude': _camera(center: const LatLng(double.nan, krakowLng)),
    'NaN longitude': _camera(center: const LatLng(krakowLat, double.nan)),
    'infinite longitude': _camera(
      center: const LatLng(krakowLat, double.infinity),
    ),
    'NaN zoom': _camera(zoom: double.nan),
    'infinite zoom': _camera(zoom: double.infinity),
    'NaN rotation': _camera(rotation: double.nan),
    'unknown size': _camera(size: const Size(-1, -1)),
    'zero size': _camera(size: Size.zero),
  };

  group('isUsable', () {
    test('accepts a normal camera', () {
      expect(_camera().isUsable, isTrue);
    });

    for (final entry in broken.entries) {
      test('rejects a camera with ${entry.key}', () {
        expect(entry.value.isUsable, isFalse);
      });
    }
  });

  group('the fog layers survive a broken camera', () {
    for (final entry in broken.entries) {
      test('painter does not throw for ${entry.key}', () async {
        final store = await openStore();
        await walk(store, 'a', points: 10);
        await store.flush();
        final healthy = cameraAt();
        final source = await readySource(store, healthy);

        final alpha = await renderAlpha(
          painterFor(entry.value, source: source),
        );

        expect(alpha(200, 400), closeTo(fogAlpha, 1));
        source.dispose();
        await store.dispose();
      });

      test('ensureVisible does not throw for ${entry.key}', () async {
        final store = await openStore();
        final source = await readySource(store, cameraAt());

        expect(() => source.ensureVisible(entry.value), returnsNormally);
        expect(
          source.levelFor(entry.value.zoom),
          inInclusiveRange(4, FogConfig.baseZoom),
        );
        source.dispose();
        await store.dispose();
      });
    }

    test('the live disc is skipped for a broken camera', () async {
      final alpha = await renderAlpha(
        painterFor(
          _camera(zoom: double.nan),
          head: const LatLng(krakowLat, krakowLng),
        ),
      );

      expect(alpha(200, 400), closeTo(fogAlpha, 1));
    });
  });
}
