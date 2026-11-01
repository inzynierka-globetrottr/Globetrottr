import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';

void main() {
  group('FogTileCodec', () {
    test('an empty mask is stored as a flag only', () {
      final encoded = FogTileCodec.encode(FogMask());

      expect(encoded.flag, FogTileCodec.flagEmpty);
      expect(encoded.bytes, isNull);
    });

    test('a full mask is stored as a flag only', () {
      final mask = FogMask();
      mask.data.fillRange(0, FogMask.pixels, 255);

      final encoded = FogTileCodec.encode(mask);

      expect(encoded.flag, FogTileCodec.flagFull);
      expect(encoded.bytes, isNull);
    });

    test('flag-only tiles decode back to the same masks', () {
      final empty = FogTileCodec.decode(FogTileCodec.flagEmpty, null);
      final full = FogTileCodec.decode(FogTileCodec.flagFull, null);

      expect(empty.isEmpty, isTrue);
      expect(full.isFull, isTrue);
    });

    test('partial masks round-trip losslessly', () {
      final mask = FogMask();
      for (var i = 0; i < FogMask.pixels; i += 7) {
        mask.data[i] = (i * 31) % 256;
      }

      final encoded = FogTileCodec.encode(mask);
      final decoded = FogTileCodec.decode(encoded.flag, encoded.bytes);

      expect(encoded.flag, FogTileCodec.flagData);
      expect(decoded.data, mask.data);
    });

    test('a decoded mask can be modified without affecting the source', () {
      final mask = FogMask()..data[10] = 200;
      final encoded = FogTileCodec.encode(mask);

      final decoded = FogTileCodec.decode(encoded.flag, encoded.bytes);
      decoded.data[10] = 1;

      expect(FogTileCodec.decode(encoded.flag, encoded.bytes).data[10], 200);
    });

    test('a sparse road tile compresses to a small blob', () {
      final mask = FogMask();
      for (var y = 100; y < 160; y++) {
        for (var x = 0; x < FogMask.size; x++) {
          mask.data[y * FogMask.size + x] = 255;
        }
      }

      final encoded = FogTileCodec.encode(mask);

      expect(encoded.bytes!.length, lessThan(1024));
    });

    test('decoding an unknown flag fails loudly', () {
      expect(
        () => FogTileCodec.decode(9, null),
        throwsA(isA<FormatException>()),
      );
    });

    test('decoding corrupted data fails loudly', () {
      expect(
        () => FogTileCodec.decode(
          FogTileCodec.flagData,
          FogMaskBytes.garbage(),
        ),
        throwsA(anything),
      );
    });

    test('the format is versioned', () {
      expect(FogTileCodec.formatVersion, 2);
    });

    test('a diagonal edge round-trips through the row filter', () {
      final mask = _diagonalMask();

      final encoded = FogTileCodec.encode(mask);

      expect(FogTileCodec.decode(encoded.flag, encoded.bytes).data, mask.data);
    });

    test('the row filter shrinks shifting edges', () {
      final mask = _diagonalMask();

      final unfiltered = ZLibCodec().encode(mask.data).length;

      expect(
        FogTileCodec.encode(mask).bytes!.length,
        lessThan(unfiltered * 0.8),
      );
    });
  });
}

abstract final class FogMaskBytes {
  static List<int> garbage() => List<int>.generate(40, (i) => i);
}

FogMask _diagonalMask() {
  final mask = FogMask();
  for (var y = 0; y < FogMask.size; y++) {
    for (var x = 0; x < FogMask.size; x++) {
      if (x < y) mask.data[y * FogMask.size + x] = 255;
      if (x == y) mask.data[y * FogMask.size + x] = 128;
    }
  }
  return mask;
}
