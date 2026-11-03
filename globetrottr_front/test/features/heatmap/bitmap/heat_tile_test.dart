import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_session_tag.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile_codec.dart';

Uint8List _coverage(Map<int, int> pixels) {
  final data = Uint8List(FogMask.pixels);
  pixels.forEach((index, value) => data[index] = value);
  return data;
}

void main() {
  group('HeatTile.countSession', () {
    test('counts a pixel once per session', () {
      final tile = HeatTile.base();
      final pass = _coverage({10: 255, 11: 255});

      expect(tile.countSession(pass, 7), isTrue);
      expect(tile.countSession(pass, 7), isFalse);

      expect(tile.counts.data[10], 1);
      expect(tile.counts.data[11], 1);
    });

    test('adds one for every other session', () {
      final tile = HeatTile.base();
      final pass = _coverage({300: 255});

      tile
        ..countSession(pass, 1)
        ..countSession(pass, 2)
        ..countSession(pass, 3);

      expect(tile.counts.data[300], 3);
    });

    test('ignores the soft rim outside the vision radius', () {
      final tile = HeatTile.base();

      final changed = tile.countSession(_coverage({5: 127, 6: 128}), 1);

      expect(changed, isTrue);
      expect(tile.counts.data[5], 0);
      expect(tile.counts.data[6], 1);
    });

    test('stops at 255 sessions', () {
      final tile = HeatTile.base();
      final pass = _coverage({0: 255});

      for (var session = 1; session <= 300; session++) {
        tile.countSession(pass, session);
      }

      expect(tile.counts.data[0], 255);
    });

    test('works on coverage that is not 8-byte aligned', () {
      final tile = HeatTile.base();
      final buffer = Uint8List(FogMask.pixels + 1);
      buffer[1 + 42] = 255;

      tile.countSession(Uint8List.sublistView(buffer, 1), 9);

      expect(tile.counts.data[42], 1);
    });
  });

  group('HeatSessionTag', () {
    test('is stable and never zero', () {
      expect(HeatSessionTag.of('session-a'), HeatSessionTag.of('session-a'));
      expect(HeatSessionTag.of('session-a'), isNot(HeatSessionTag.of('b')));
      for (var i = 0; i < 2000; i++) {
        expect(HeatSessionTag.of('s$i'), inInclusiveRange(1, 0xFFFF));
      }
    });
  });

  group('HeatTileCodec', () {
    test('keeps counts and session tags of a base tile', () {
      final tile = HeatTile.base()..countSession(_coverage({1: 255}), 5);
      tile.countSession(_coverage({1: 255, 2: 255}), 6);

      final encoded = HeatTileCodec.encode(tile);
      final decoded = HeatTileCodec.decode(encoded.flag, encoded.bytes);

      expect(decoded.counts.data[1], 2);
      expect(decoded.counts.data[2], 1);
      expect(decoded.tags![1], 6);
      expect(decoded.tags![2], 6);
    });

    test('stores overview tiles as plain fog tiles', () {
      final tile = HeatTile.overview()..counts.data[3] = 9;

      final encoded = HeatTileCodec.encode(tile);
      final decoded = HeatTileCodec.decode(encoded.flag, encoded.bytes);

      expect(decoded.tags, isNull);
      expect(decoded.counts.data[3], 9);
    });

    test('stores an untouched tile without a payload', () {
      final encoded = HeatTileCodec.encode(HeatTile.base());

      expect(encoded.bytes, isNull);
      expect(HeatTileCodec.decode(encoded.flag, null).counts.isEmpty, isTrue);
    });
  });
}
