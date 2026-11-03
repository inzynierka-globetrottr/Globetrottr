import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_density.dart';

/// Alpha grows with the step, so the alpha of a pixel shows its density.
final _recipe = HeatDensityRecipe(
  boxRadius: 8,
  unit: 0.05,
  saturation: 8,
  levels: Uint32List.fromList([for (var i = 0; i < 256; i++) i << 24]),
);

Uint8List _counts(Map<(int, int), int> pixels) {
  final data = Uint8List(FogMask.pixels);
  pixels.forEach((at, value) => data[at.$2 * FogMask.size + at.$1] = value);
  return data;
}

/// Alpha of tile pixel (x, y) in the built image (which has a 1 px border).
int Function(int x, int y) _alpha(Uint8List pixels) {
  return (x, y) => pixels[((y + 1) * FogTilePixels.side + x + 1) * 4 + 3];
}

List<Uint8List?> _alone(Uint8List centre) => [
  null, null, null, //
  null, centre, null, //
  null, null, null, //
];

void main() {
  test('a tile with nothing around it stays transparent', () {
    final alpha = _alpha(HeatDensity.build(List.filled(9, null), _recipe));

    expect(alpha(128, 128), 0);
  });

  test('a busy place spreads into a patch that fades with distance', () {
    final square = {
      for (var y = 124; y < 132; y++)
        for (var x = 124; x < 132; x++) (x, y): 20,
    };
    final alpha = _alpha(HeatDensity.build(_alone(_counts(square)), _recipe));

    expect(alpha(128, 128), greaterThan(alpha(140, 128)));
    expect(alpha(140, 128), greaterThan(alpha(150, 128)));
    expect(alpha(140, 128), greaterThan(0));
    expect(alpha(220, 128), 0);
  });

  test('more sessions make a place hotter', () {
    final once = _alpha(
      HeatDensity.build(_alone(_counts({(128, 128): 1})), _recipe),
    );
    final often = _alpha(
      HeatDensity.build(_alone(_counts({(128, 128): 40})), _recipe),
    );

    expect(often(128, 128), greaterThan(once(128, 128)));
  });

  test('a patch crosses into the tile next to it', () {
    final west = _counts({
      for (var y = 120; y < 136; y++)
        for (var x = 250; x < 256; x++) (x, y): 30,
    });
    final alpha = _alpha(
      HeatDensity.build([
        null,
        null,
        null,
        west,
        null,
        null,
        null,
        null,
        null,
      ], _recipe),
    );

    expect(alpha(0, 128), greaterThan(0));
    expect(alpha(128, 128), 0);
  });

  test('a higher contrast keeps a middling place lower on the scale', () {
    final counts = _alone(_counts({(128, 128): 10}));
    final steep = HeatDensityRecipe(
      boxRadius: _recipe.boxRadius,
      unit: _recipe.unit,
      saturation: _recipe.saturation,
      contrast: 2,
      levels: _recipe.levels,
    );

    final plain = _alpha(HeatDensity.build(counts, _recipe))(128, 128);
    final sharp = _alpha(HeatDensity.build(counts, steep))(128, 128);

    expect(sharp, lessThan(plain));
    expect(sharp, greaterThan(0));
  });
}
