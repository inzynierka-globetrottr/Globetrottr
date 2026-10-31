import 'dart:typed_data';

/// 256x256 grid of 8-bit discovery coverage: 0 is fog, 255 is fully revealed.
class FogMask {
  FogMask() : data = Uint8List(pixels);

  FogMask.fromBytes(this.data)
    : assert(data.length == pixels, 'A mask needs exactly $pixels bytes');

  static const int size = 256;
  static const int pixels = size * size;

  final Uint8List data;

  int at(int x, int y) => data[y * size + x];

  bool get isEmpty => _allWords(0) ?? data.every((v) => v == 0);

  bool get isFull => _allWords(-1) ?? data.every((v) => v == 255);

  int get coveredSum {
    var sum = 0;
    for (var i = 0; i < pixels; i++) {
      sum += data[i];
    }
    return sum;
  }

  /// Keeps the larger value of every pixel. Returns whether any pixel
  /// changed, so a caller can tell a merge that added nothing.
  bool mergeMax(FogMask other) {
    final source = other.data;
    var changed = false;
    for (var i = 0; i < pixels; i++) {
      if (source[i] > data[i]) {
        data[i] = source[i];
        changed = true;
      }
    }
    return changed;
  }

  /// Rounds every value to the nearest multiple of [step] (0 and 255 stay).
  ///
  /// Sixteen levels (step 16) are invisible on the 1.5 px rim but make a tile
  /// compress about three times smaller. The operation is idempotent and
  /// monotone, so `quantize(max(a, b)) == max(quantize(a), quantize(b))`:
  /// drawing again over stored (quantized) tiles gives the same result as
  /// never having quantized, which keeps replays after a crash exact.
  void quantizeInPlace({int step = 16}) {
    final half = step ~/ 2;
    for (var i = 0; i < pixels; i++) {
      final value = data[i];
      if (value == 0 || value == 255) continue;
      final rounded = (value + half) ~/ step * step;
      data[i] = rounded > 255 ? 255 : rounded;
    }
  }

  /// Compares the mask as 64-bit words, which is 8x faster than per byte.
  /// Returns null when the backing buffer is not 8-byte aligned.
  bool? _allWords(int expected) {
    if (data.offsetInBytes % 8 != 0) return null;
    final words = data.buffer.asUint64List(data.offsetInBytes, pixels ~/ 8);
    for (var i = 0; i < words.length; i++) {
      if (words[i] != expected) return false;
    }
    return true;
  }
}
