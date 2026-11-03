import 'dart:io';
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/heatmap/bitmap/heat_tile.dart';

/// Serialization of a heatmap tile.
///
/// Overview tiles are plain fog tiles (`FogTileCodec`, flags 0 to 2) whose
/// values are session counts. A base tile with counts uses flag 3: zlib of
/// the 65536 counts followed by the 65536 session tags (little endian
/// 16-bit), both in row-major order.
abstract final class HeatTileCodec {
  static const int flagBase = 3;

  static final ZLibCodec _zlib = ZLibCodec();

  static EncodedFogTile encode(HeatTile tile) {
    final tags = tile.tags;
    if (tags == null || tile.counts.isEmpty) {
      return FogTileCodec.encode(tile.counts);
    }
    final raw = Uint8List(FogMask.pixels * 3)
      ..setAll(0, tile.counts.data)
      ..setAll(FogMask.pixels, tags.buffer.asUint8List(tags.offsetInBytes));
    return EncodedFogTile(flagBase, Uint8List.fromList(_zlib.encode(raw)));
  }

  static HeatTile decode(int flag, List<int>? bytes) {
    if (flag != flagBase) {
      return HeatTile(FogTileCodec.decode(flag, bytes), null);
    }
    final raw = Uint8List.fromList(_zlib.decode(bytes!));
    if (raw.length != FogMask.pixels * 3) {
      throw FormatException('Heat tile of ${raw.length} bytes');
    }
    final counts = FogMask.fromBytes(raw.sublist(0, FogMask.pixels));
    final tags = Uint16List(FogMask.pixels);
    tags.buffer.asUint8List().setAll(0, raw.sublist(FogMask.pixels));
    return HeatTile(counts, tags);
  }
}
