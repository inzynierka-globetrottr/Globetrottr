import 'dart:math' as math;

import 'package:globetrottr_front/features/heatmap/heat_config.dart';

/// Where a session count lies on the colour scale of the heatmap: one
/// session is 0, [HeatConfig.saturationSessions] and more are 1, and the
/// counts in between follow the logarithm, so the first visits are told apart
/// best.
abstract final class HeatLevels {
  /// Position of [sessions] on the scale, or null for a place nobody passed.
  static double? shareOf(int sessions) {
    if (sessions <= 0) return null;
    final share = math.log(sessions) / math.log(HeatConfig.saturationSessions);
    return share.clamp(0.0, 1.0);
  }
}
