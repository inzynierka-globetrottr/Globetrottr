import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/heatmap/heat_config.dart';

/// One tile of the heatmap: per pixel, how many sessions passed it.
///
/// [counts] uses the fog's tile layout, so the fog's pyramid, tile source and
/// renderer work on it unchanged. Base tiles also keep [tags], the session
/// that last counted each pixel; overview tiles only show the counts.
class HeatTile {
  HeatTile(this.counts, this.tags);

  HeatTile.base() : counts = FogMask(), tags = Uint16List(FogMask.pixels);

  HeatTile.overview() : counts = FogMask(), tags = null;

  final FogMask counts;
  final Uint16List? tags;

  /// Adds one for every pixel [coverage] reaches that [tag] has not counted
  /// yet. Returns whether the tile changed.
  bool countSession(Uint8List coverage, int tag) {
    final tags = this.tags!;
    final counts = this.counts.data;
    var changed = false;

    void countFrom(int start, int end) {
      for (var i = start; i < end; i++) {
        if (coverage[i] < HeatConfig.countedCoverage || tags[i] == tag) {
          continue;
        }
        tags[i] = tag;
        if (counts[i] < 255) counts[i]++;
        changed = true;
      }
    }

    // A pass covers a small part of a tile: skipping empty 64-bit words makes
    // the scan about 8x faster than per byte.
    if (coverage.offsetInBytes % 8 != 0) {
      countFrom(0, FogMask.pixels);
      return changed;
    }
    final words = coverage.buffer.asUint64List(
      coverage.offsetInBytes,
      FogMask.pixels ~/ 8,
    );
    for (var w = 0; w < words.length; w++) {
      if (words[w] != 0) countFrom(w * 8, w * 8 + 8);
    }
    return changed;
  }
}
