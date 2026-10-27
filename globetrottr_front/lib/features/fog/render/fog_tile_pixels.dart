import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';

/// Converts a coverage mask to the RGBA pixels of a GPU image.
///
/// The image is 258x258: the tile plus a 1 px border copied from the
/// neighbouring tiles (or replicated from the tile itself when a neighbour is
/// not available). Sampling with bilinear filtering then stays continuous
/// across tile borders, so no seams appear. Colour is black and the alpha
/// channel is the coverage, ready to be subtracted from the fog.
abstract final class FogTilePixels {
  static const int side = FogMask.size + 2;

  static Uint8List build(
    FogMask mask, {
    required FogMask? Function(int dx, int dy) neighbor,
  }) {
    const size = FogMask.size;
    final pixels = Uint8List(side * side * 4);
    final data = mask.data;

    void put(int x, int y, int value) {
      pixels[(y * side + x) * 4 + 3] = value;
    }

    for (var y = 0; y < size; y++) {
      final row = y * size;
      final target = ((y + 1) * side + 1) * 4 + 3;
      for (var x = 0; x < size; x++) {
        pixels[target + x * 4] = data[row + x];
      }
    }

    final north = neighbor(0, -1);
    final south = neighbor(0, 1);
    final west = neighbor(-1, 0);
    final east = neighbor(1, 0);
    for (var i = 0; i < size; i++) {
      put(i + 1, 0, north?.at(i, size - 1) ?? mask.at(i, 0));
      put(i + 1, side - 1, south?.at(i, 0) ?? mask.at(i, size - 1));
      put(0, i + 1, west?.at(size - 1, i) ?? mask.at(0, i));
      put(side - 1, i + 1, east?.at(0, i) ?? mask.at(size - 1, i));
    }

    put(0, 0, neighbor(-1, -1)?.at(size - 1, size - 1) ?? mask.at(0, 0));
    put(side - 1, 0, neighbor(1, -1)?.at(0, size - 1) ?? mask.at(size - 1, 0));
    put(0, side - 1, neighbor(-1, 1)?.at(size - 1, 0) ?? mask.at(0, size - 1));
    put(
      side - 1,
      side - 1,
      neighbor(1, 1)?.at(0, 0) ?? mask.at(size - 1, size - 1),
    );
    return pixels;
  }
}
