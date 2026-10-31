import 'dart:io';
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';

class EncodedFogTile {
  const EncodedFogTile(this.flag, this.bytes);

  final int flag;
  final Uint8List? bytes;
}

/// Serialization of a fog tile.
///
/// Format version 2 (language neutral, so a backend can read it as is):
/// - the tile is the standard XYZ tile `z/x/y` of 256x256 pixels;
/// - pixel values are 8-bit coverage, 0 is fog, 255 is revealed;
/// - `flag` 0: the tile is empty, there is no payload;
/// - `flag` 1: every pixel is 255, there is no payload;
/// - `flag` 2: the payload is the 65536 pixels in row-major order from the
///   top-left corner, with every row except the first replaced by its
///   difference from the row above (modulo 256), compressed with zlib
///   (RFC 1950). Decoding is a zlib inflate followed by a running sum down
///   each column. Stored values are multiples of 8 (and 255).
abstract final class FogTileCodec {
  static const int formatVersion = 2;
  static const int flagEmpty = 0;
  static const int flagFull = 1;
  static const int flagData = 2;

  static final ZLibCodec _zlib = ZLibCodec();

  static EncodedFogTile encode(FogMask mask) {
    if (mask.isEmpty) return const EncodedFogTile(flagEmpty, null);
    if (mask.isFull) return const EncodedFogTile(flagFull, null);
    return EncodedFogTile(
      flagData,
      Uint8List.fromList(_zlib.encode(_rowDifference(mask.data))),
    );
  }

  static FogMask decode(int flag, List<int>? bytes) {
    switch (flag) {
      case flagEmpty:
        return FogMask();
      case flagFull:
        final mask = FogMask();
        mask.data.fillRange(0, FogMask.pixels, 255);
        return mask;
      case flagData:
        final filtered = Uint8List.fromList(_zlib.decode(bytes!));
        if (filtered.length != FogMask.pixels) {
          throw FormatException('Fog tile of ${filtered.length} bytes');
        }
        return FogMask.fromBytes(_restoreRows(filtered));
      default:
        throw FormatException('Unknown fog tile flag: $flag');
    }
  }

  static Uint8List _rowDifference(Uint8List raw) {
    const row = FogMask.size;
    final out = Uint8List(raw.length);
    for (var i = 0; i < row; i++) {
      out[i] = raw[i];
    }
    for (var i = row; i < raw.length; i++) {
      out[i] = (raw[i] - raw[i - row]) & 0xFF;
    }
    return out;
  }

  static Uint8List _restoreRows(Uint8List filtered) {
    const row = FogMask.size;
    for (var i = row; i < filtered.length; i++) {
      filtered[i] = (filtered[i] + filtered[i - row]) & 0xFF;
    }
    return filtered;
  }
}
