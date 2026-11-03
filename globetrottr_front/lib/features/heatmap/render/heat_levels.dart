import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';
import 'package:globetrottr_front/features/heatmap/heat_config.dart';

/// How the session count of a pixel becomes the brightness the painter
/// colours: 0 stays black (nothing drawn), one session is [first], and the
/// rest grows with the logarithm of the count up to white at
/// [HeatConfig.saturationSessions].
abstract final class HeatLevels {
  static const int first = 96;

  static int brightnessOf(int sessions) {
    if (sessions <= 0) return 0;
    final share = math.log(sessions) / math.log(HeatConfig.saturationSessions);
    return (first + (255 - first) * share.clamp(0.0, 1.0)).round();
  }

  static final Uint32List greys = FogTilePixels.greysOf(brightnessOf);
}
