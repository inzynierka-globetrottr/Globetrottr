import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_rasterizer.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';

const _zoom = 5;
const _rasterizer = FogRasterizer(zoom: _zoom, edgeWidth: 1.5);

class _Canvas {
  final Map<FogTileId, FogMask> tiles = {};

  FogMask maskFor(FogTileId id) => tiles.putIfAbsent(id, FogMask.new);

  int pixel(int x, int y) {
    final id = FogTileId(_zoom, x ~/ FogMask.size, y ~/ FogMask.size);
    final mask = tiles[id];
    if (mask == null) return 0;
    return mask.at(x % FogMask.size, y % FogMask.size);
  }

  double get area =>
      tiles.values.fold<int>(0, (sum, mask) => sum + mask.coveredSum) / 255.0;
}

double _distanceToSegment(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  return math.sqrt(
    math.pow(px - (ax + t * dx), 2) + math.pow(py - (ay + t * dy), 2),
  );
}

void main() {
  quantizedRasterizerTests();

  group('FogRasterizer', () {
    test('a disc has the area of a circle', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 400,
        ay: 400,
        bx: 400,
        by: 400,
        radius: 40,
        maskFor: canvas.maskFor,
      );

      expect(canvas.area, closeTo(math.pi * 40 * 40, math.pi * 40 * 40 * 0.01));
    });

    test('a stadium has the area of a capsule', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 300,
        ay: 300,
        bx: 500,
        by: 380,
        radius: 25,
        maskFor: canvas.maskFor,
      );

      final length = math.sqrt(200 * 200 + 80 * 80);
      final expected = 2 * 25 * length + math.pi * 25 * 25;
      expect(canvas.area, closeTo(expected, expected * 0.01));
    });

    test('pixels are fully covered inside and empty outside the radius', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 300,
        ay: 300,
        bx: 400,
        by: 300,
        radius: 20,
        maskFor: canvas.maskFor,
      );

      expect(canvas.pixel(350, 300), 255);
      expect(canvas.pixel(350, 285), 255);
      expect(canvas.pixel(350, 330), 0);
      expect(canvas.pixel(278, 300), 0);
      expect(canvas.pixel(270, 300), 0);
    });

    test('coverage is one half at exactly the radius', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 300.5,
        ay: 300.5,
        bx: 400.5,
        by: 300.5,
        radius: 20,
        maskFor: canvas.maskFor,
      );

      expect(canvas.pixel(350, 300 - 20), closeTo(128, 3));
      expect(canvas.pixel(350, 300 + 20), closeTo(128, 3));
    });

    test('matches the analytic coverage for every pixel', () {
      final canvas = _Canvas();
      const ax = 270.3;
      const ay = 255.1;
      const bx = 330.7;
      const by = 270.9;
      const radius = 14.0;
      _rasterizer.drawStadium(
        ax: ax,
        ay: ay,
        bx: bx,
        by: by,
        radius: radius,
        maskFor: canvas.maskFor,
      );

      var maxError = 0;
      for (var y = 220; y < 310; y++) {
        for (var x = 235; x < 370; x++) {
          final d = _distanceToSegment(x + 0.5, y + 0.5, ax, ay, bx, by);
          final expected = (((radius + 0.75 - d) / 1.5).clamp(0.0, 1.0) * 255)
              .round();
          maxError = math.max(maxError, (canvas.pixel(x, y) - expected).abs());
        }
      }

      expect(maxError, lessThanOrEqualTo(1));
    });

    test('is continuous across tile borders', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 200,
        ay: 250,
        bx: 330,
        by: 262,
        radius: 18,
        maskFor: canvas.maskFor,
      );

      expect(canvas.tiles.keys.map((id) => id.x).toSet(), {0, 1});
      expect(canvas.tiles.keys.map((id) => id.y).toSet(), {0, 1});
      for (var y = 240; y < 275; y++) {
        final left = canvas.pixel(255, y);
        final right = canvas.pixel(256, y);
        expect((left - right).abs(), lessThan(40), reason: 'row $y');
      }
      expect(canvas.pixel(255, 256), 255);
      expect(canvas.pixel(256, 256), 255);
    });

    test('has no gaps between consecutive segments of a polyline', () {
      final canvas = _Canvas();
      const points = [
        [300.0, 300.0],
        [310.0, 304.0],
        [322.0, 301.0],
        [335.0, 310.0],
      ];

      for (var i = 0; i < points.length - 1; i++) {
        _rasterizer.drawStadium(
          ax: points[i][0],
          ay: points[i][1],
          bx: points[i + 1][0],
          by: points[i + 1][1],
          radius: 8,
          maskFor: canvas.maskFor,
        );
      }

      for (var t = 0.0; t <= 1.0; t += 0.01) {
        final x = 300 + t * 35;
        final y = 300 + t * 10;
        expect(canvas.pixel(x.round(), y.round()), 255);
      }
    });

    test('overlapping shapes are merged with max, not added', () {
      final canvas = _Canvas();
      void draw() => _rasterizer.drawStadium(
        ax: 300,
        ay: 300,
        bx: 340,
        by: 300,
        radius: 12,
        maskFor: canvas.maskFor,
      );

      draw();
      final once = canvas.area;
      draw();

      expect(canvas.area, once);
    });

    test('drawing never lowers an existing value', () {
      final canvas = _Canvas();
      _rasterizer.drawStadium(
        ax: 300,
        ay: 300,
        bx: 300,
        by: 300,
        radius: 30,
        maskFor: canvas.maskFor,
      );
      final before = canvas.pixel(300, 300);

      _rasterizer.drawStadium(
        ax: 310,
        ay: 300,
        bx: 310,
        by: 300,
        radius: 2,
        maskFor: canvas.maskFor,
      );

      expect(canvas.pixel(300, 300), before);
    });

    test('only creates masks for tiles that receive pixels', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 128,
        ay: 128,
        bx: 128,
        by: 128,
        radius: 10,
        maskFor: canvas.maskFor,
      );

      expect(canvas.tiles.keys, [const FogTileId(_zoom, 0, 0)]);
    });

    test('tilesFor names every tile the stadium draws into', () {
      const shapes = [
        (ax: 250.0, ay: 100.0, bx: 270.0, by: 100.0, radius: 10.0),
        (ax: 100.0, ay: 100.0, bx: 600.0, by: 700.0, radius: 20.0),
        (ax: 255.5, ay: 255.5, bx: 255.5, by: 255.5, radius: 0.5),
      ];
      for (final shape in shapes) {
        final canvas = _Canvas();

        _rasterizer.drawStadium(
          ax: shape.ax,
          ay: shape.ay,
          bx: shape.bx,
          by: shape.by,
          radius: shape.radius,
          maskFor: canvas.maskFor,
        );

        final range = _rasterizer.tilesFor(
          ax: shape.ax,
          ay: shape.ay,
          bx: shape.bx,
          by: shape.by,
          radius: shape.radius,
        );
        expect(canvas.tiles.keys.every(range.contains), isTrue);
      }
    });

    test('clips shapes at the edge of the world', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 2,
        ay: 2,
        bx: 2,
        by: 2,
        radius: 20,
        maskFor: canvas.maskFor,
      );

      expect(canvas.tiles.keys, [const FogTileId(_zoom, 0, 0)]);
      expect(canvas.pixel(0, 0), 255);
    });

    test('a very small radius still produces coverage', () {
      final canvas = _Canvas();

      _rasterizer.drawStadium(
        ax: 100.5,
        ay: 100.5,
        bx: 100.5,
        by: 100.5,
        radius: 0.4,
        maskFor: canvas.maskFor,
      );

      expect(canvas.pixel(100, 100), greaterThan(0));
    });

    group('onChanged', () {
      List<FogTileId> draw(
        _Canvas canvas, {
        required double ax,
        required double bx,
        double radius = 20,
        double ay = 300,
        double by = 300,
      }) {
        final changed = <FogTileId>[];
        _rasterizer.drawStadium(
          ax: ax,
          ay: ay,
          bx: bx,
          by: by,
          radius: radius,
          maskFor: canvas.maskFor,
          onChanged: changed.add,
        );
        return changed;
      }

      test('reports the tile of a first drawing', () {
        final canvas = _Canvas();

        final changed = draw(canvas, ax: 100, bx: 140);

        expect(changed.toSet(), {const FogTileId(_zoom, 0, 1)});
      });

      test('reports each changed tile once', () {
        final canvas = _Canvas();

        final changed = draw(canvas, ax: 200, bx: 330, ay: 250, by: 262);

        expect(changed.length, changed.toSet().length);
        expect(changed.length, greaterThan(1));
      });

      test('reports nothing when the same shape is drawn again', () {
        final canvas = _Canvas();
        draw(canvas, ax: 100, bx: 140);

        final again = draw(canvas, ax: 100, bx: 140);

        expect(again, isEmpty);
      });

      test('reports nothing for a shape inside an existing one', () {
        final canvas = _Canvas();
        draw(canvas, ax: 100, bx: 200, radius: 30);

        final inside = draw(canvas, ax: 130, bx: 170, radius: 10);

        expect(inside, isEmpty);
      });

      test('reports a drawing that makes the shape wider', () {
        final canvas = _Canvas();
        draw(canvas, ax: 100, bx: 140, radius: 10);

        final wider = draw(canvas, ax: 100, bx: 140);

        expect(wider, isNotEmpty);
      });

      test('reports only the tiles where something is new', () {
        final canvas = _Canvas();
        draw(canvas, ax: 100, bx: 330, ay: 100, by: 100);

        final changed = draw(canvas, ax: 100, bx: 345, ay: 100, by: 100);

        expect(changed.toSet(), {const FogTileId(_zoom, 1, 0)});
      });

      test('the pixels end up the same whether or not it is reported', () {
        final canvas = _Canvas();
        draw(canvas, ax: 100, bx: 140);
        final before = canvas.area;

        draw(canvas, ax: 100, bx: 140);

        expect(canvas.area, before);
      });
    });
  });
}

void quantizedRasterizerTests() {
  group('FogRasterizer with a quantization step', () {
    const rasterizer = FogRasterizer(zoom: _zoom, quantStep: 16);

    test('only writes multiples of the step and 255', () {
      final canvas = _Canvas();

      rasterizer.drawStadium(
        ax: 100.3,
        ay: 100.7,
        bx: 140.9,
        by: 103.1,
        radius: 12.4,
        maskFor: canvas.maskFor,
      );

      for (final mask in canvas.tiles.values) {
        for (final value in mask.data) {
          expect(value == 255 || value % 16 == 0, isTrue, reason: '$value');
        }
      }
    });

    test('drawing again over stored, quantized tiles changes nothing', () {
      final canvas = _Canvas();
      void draw(void Function(FogTileId id)? onChanged) {
        rasterizer.drawStadium(
          ax: 100.3,
          ay: 100.7,
          bx: 140.9,
          by: 103.1,
          radius: 12.4,
          maskFor: canvas.maskFor,
          onChanged: onChanged,
        );
      }

      draw(null);
      for (final mask in canvas.tiles.values) {
        mask.quantizeInPlace();
      }
      final changed = <FogTileId>[];
      draw(changed.add);

      expect(changed, isEmpty);
    });

    test('quantizing while drawing equals quantizing afterwards', () {
      final plain = _Canvas();
      const raw = FogRasterizer(zoom: _zoom);
      final quantized = _Canvas();

      for (final target in [(plain, raw), (quantized, rasterizer)]) {
        target.$2.drawStadium(
          ax: 90.5,
          ay: 120.5,
          bx: 160.5,
          by: 130.5,
          radius: 15,
          maskFor: target.$1.maskFor,
        );
        target.$2.drawStadium(
          ax: 120.5,
          ay: 100.5,
          bx: 125.5,
          by: 160.5,
          radius: 9,
          maskFor: target.$1.maskFor,
        );
      }
      for (final mask in plain.tiles.values) {
        mask.quantizeInPlace();
      }

      for (final entry in plain.tiles.entries) {
        expect(quantized.tiles[entry.key]!.data, entry.value.data);
      }
    });
  });
}
