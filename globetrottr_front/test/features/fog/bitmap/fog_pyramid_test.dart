import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';

FogMask _fullMask() {
  final mask = FogMask();
  mask.data.fillRange(0, FogMask.pixels, 255);
  return mask;
}

void main() {
  group('FogPyramid.downsampleInto', () {
    test('an empty child clears its quadrant', () {
      final parent = _fullMask();

      FogPyramid.downsampleInto(
        child: FogMask(),
        parent: parent,
        quadX: 0,
        quadY: 0,
      );

      expect(parent.at(0, 0), 0);
      expect(parent.at(127, 127), 0);
      expect(parent.at(128, 0), 255);
      expect(parent.at(0, 128), 255);
    });

    test('a full child fills its quadrant', () {
      final parent = FogMask();

      FogPyramid.downsampleInto(
        child: _fullMask(),
        parent: parent,
        quadX: 1,
        quadY: 1,
      );

      expect(parent.at(128, 128), 255);
      expect(parent.at(255, 255), 255);
      expect(parent.at(127, 127), 0);
      expect(parent.at(255, 0), 0);
    });

    test('places each child in its own quadrant', () {
      final child = FogMask()..data[0] = 255;

      for (final quad in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
        final parent = FogMask();
        FogPyramid.downsampleInto(
          child: child,
          parent: parent,
          quadX: quad.$1,
          quadY: quad.$2,
        );

        expect(parent.at(quad.$1 * 128, quad.$2 * 128), greaterThan(0));
        expect(parent.coveredSum, parent.at(quad.$1 * 128, quad.$2 * 128));
      }
    });

    test('averages dense coverage', () {
      final child = FogMask();
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 2; x++) {
          child.data[y * FogMask.size + x] = 200;
        }
      }
      child.data[1] = 100;
      child.data[FogMask.size + 1] = 100;

      final parent = FogMask();
      FogPyramid.downsampleInto(
        child: child,
        parent: parent,
        quadX: 0,
        quadY: 0,
      );

      expect(parent.at(0, 0), 150);
    });

    test('a single revealed pixel stays visible instead of averaging away', () {
      final child = FogMask()..data[0] = 255;
      final parent = FogMask();

      FogPyramid.downsampleInto(
        child: child,
        parent: parent,
        quadX: 0,
        quadY: 0,
      );

      expect(parent.at(0, 0), FogPyramid.defaultOverviewFloor);
      expect(parent.at(0, 0), greaterThanOrEqualTo(128));
    });

    test('faint edge values are not boosted beyond themselves', () {
      final child = FogMask()..data[0] = 30;
      final parent = FogMask();

      FogPyramid.downsampleInto(
        child: child,
        parent: parent,
        quadX: 0,
        quadY: 0,
      );

      expect(parent.at(0, 0), 30);
    });

    test('a thin line keeps its visibility over many levels', () {
      var current = FogMask();
      for (var x = 0; x < FogMask.size; x++) {
        current.data[100 * FogMask.size + x] = 255;
      }

      for (var level = 0; level < 6; level++) {
        final next = FogMask();
        FogPyramid.downsampleInto(
          child: current,
          parent: next,
          quadX: 0,
          quadY: 0,
        );
        current = next;
        var strongest = 0;
        for (var i = 0; i < FogMask.pixels; i++) {
          if (current.data[i] > strongest) strongest = current.data[i];
        }
        expect(strongest, greaterThanOrEqualTo(128), reason: 'level $level');
      }
    });

    test('overwrites the quadrant instead of merging', () {
      final parent = _fullMask();
      final child = FogMask()..data[0] = 255;

      FogPyramid.downsampleInto(
        child: child,
        parent: parent,
        quadX: 0,
        quadY: 0,
      );

      expect(parent.at(1, 0), 0);
    });

    test('a custom floor changes how strongly thin features are shown', () {
      final child = FogMask()..data[0] = 255;
      final parent = FogMask();

      FogPyramid.downsampleInto(
        child: child,
        parent: parent,
        quadX: 0,
        quadY: 0,
        overviewFloor: 200,
      );

      expect(parent.at(0, 0), 200);
    });
  });
}
