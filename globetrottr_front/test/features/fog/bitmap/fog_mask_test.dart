import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';

FogMask _copy(FogMask mask) => FogMask.fromBytes(Uint8List.fromList(mask.data));

void main() {
  group('FogMask', () {
    test('starts empty', () {
      final mask = FogMask();

      expect(mask.isEmpty, isTrue);
      expect(mask.isFull, isFalse);
      expect(mask.data.length, FogMask.pixels);
      expect(mask.coveredSum, 0);
    });

    test('is no longer empty after setting a pixel', () {
      final mask = FogMask()..data[FogMask.pixels - 1] = 1;

      expect(mask.isEmpty, isFalse);
    });

    test('is full only when every pixel is 255', () {
      final mask = FogMask();
      mask.data.fillRange(0, FogMask.pixels, 255);
      expect(mask.isFull, isTrue);

      mask.data[12345] = 254;
      expect(mask.isFull, isFalse);
    });

    test('reads and writes pixels by coordinates', () {
      final mask = FogMask();
      mask.data[3 * FogMask.size + 7] = 99;

      expect(mask.at(7, 3), 99);
      expect(mask.at(3, 7), 0);
    });

    test('mergeMax keeps the larger value per pixel', () {
      final a = FogMask();
      final b = FogMask();
      a.data[0] = 10;
      a.data[1] = 200;
      b.data[0] = 50;
      b.data[1] = 20;
      b.data[2] = 7;

      a.mergeMax(b);

      expect(a.data[0], 50);
      expect(a.data[1], 200);
      expect(a.data[2], 7);
    });

    test('mergeMax with itself or an empty mask changes nothing', () {
      final a = FogMask();
      a.data[5] = 80;
      final copy = _copy(a);

      a.mergeMax(a);
      a.mergeMax(FogMask());

      expect(a.data, copy.data);
    });

    test('fromBytes validates the length', () {
      expect(() => FogMask.fromBytes(Uint8List(10)), throwsA(isA<Error>()));
    });

    test('works for data that is not 8-byte aligned', () {
      final backing = Uint8List(FogMask.pixels + 8);
      final view = Uint8List.sublistView(backing, 3, 3 + FogMask.pixels);
      final mask = FogMask.fromBytes(view);

      expect(mask.isEmpty, isTrue);
      view[100] = 1;
      expect(mask.isEmpty, isFalse);
    });

    test('quantizeInPlace rounds to 16 levels and keeps 0 and 255', () {
      final mask = FogMask();
      const input = [
        0,
        1,
        7,
        8,
        23,
        24,
        100,
        127,
        128,
        240,
        247,
        248,
        254,
        255,
      ];
      const expected = [
        0,
        0,
        0,
        16,
        16,
        32,
        96,
        128,
        128,
        240,
        240,
        255,
        255,
        255,
      ];
      for (var i = 0; i < input.length; i++) {
        mask.data[i] = input[i];
      }

      mask.quantizeInPlace();

      expect(mask.data.sublist(0, input.length), expected);
    });

    test('quantizeInPlace supports a coarser step for overview tiles', () {
      final mask = FogMask();
      const input = [0, 15, 16, 47, 48, 100, 144, 150, 240, 254, 255];
      const expected = [0, 0, 32, 32, 64, 96, 160, 160, 255, 255, 255];
      for (var i = 0; i < input.length; i++) {
        mask.data[i] = input[i];
      }

      mask.quantizeInPlace(step: 32);

      expect(mask.data.sublist(0, input.length), expected);
    });

    test('quantizeInPlace is idempotent and monotone', () {
      final mask = FogMask();
      for (var i = 0; i < 256; i++) {
        mask.data[i] = i;
      }
      mask.quantizeInPlace();
      final once = Uint8List.fromList(mask.data);

      mask.quantizeInPlace();

      expect(mask.data, once);
      for (var i = 1; i < 256; i++) {
        expect(mask.data[i], greaterThanOrEqualTo(mask.data[i - 1]));
      }
    });

    test('quantizing after a max merge equals merging quantized masks', () {
      final a = FogMask();
      final b = FogMask();
      for (var i = 0; i < FogMask.pixels; i++) {
        a.data[i] = (i * 37) % 256;
        b.data[i] = (i * 91 + 13) % 256;
      }
      final merged = _copy(a)..mergeMax(b);
      final qa = _copy(a)..quantizeInPlace();
      final viaStored = _copy(qa)..mergeMax(b);
      merged.quantizeInPlace();
      viaStored.quantizeInPlace();

      expect(viaStored.data, merged.data);
    });

    test('coveredSum adds all pixel values', () {
      final mask = FogMask();
      mask.data[0] = 255;
      mask.data[1] = 100;

      expect(mask.coveredSum, 355);
    });

    test('mergeMax says whether anything changed', () {
      final a = FogMask()..data[0] = 100;
      final lower = FogMask()..data[0] = 50;
      final higher = FogMask()..data[0] = 150;

      expect(a.mergeMax(lower), isFalse);
      expect(a.mergeMax(_copy(a)), isFalse);
      expect(a.mergeMax(FogMask()), isFalse);
      expect(a.mergeMax(higher), isTrue);
      expect(a.data[0], 150);
    });
  });
}
