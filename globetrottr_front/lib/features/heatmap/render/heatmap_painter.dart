import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_drawer.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_levels.dart';

/// Paints the heatmap: the fog's tile images, whose brightness grows with
/// the number of sessions (see [HeatLevels]), coloured by one colour filter
/// from [cold] to [hot]. Brightness also sets the opacity, so places visited
/// rarely stay faint and nothing is drawn where nobody went.
class HeatmapPainter extends CustomPainter {
  HeatmapPainter({
    required this.camera,
    required this.cold,
    required this.hot,
    this.source,
  }) : super(repaint: source);

  final MapCamera camera;
  final Color cold;
  final Color hot;
  final HeatTileSource? source;

  @override
  void paint(Canvas canvas, Size size) {
    final source = this.source;
    if (source == null || !camera.isUsableForFog) return;
    final timer = Stopwatch()..start();
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..colorFilter = spectrum(cold, hot),
    );
    canvas.drawColor(Colors.black, BlendMode.src);
    FogTileDrawer(camera).drawTiles(canvas, source);
    canvas.restore();
    source.stats.record(timer.elapsedMicroseconds);
  }

  /// Maps the brightness of the layer to a colour: [HeatLevels.first] is
  /// [cold], white is [hot], linearly in between, and the opacity grows with
  /// the brightness up to that of [hot].
  static ColorFilter spectrum(Color cold, Color hot) {
    const first = HeatLevels.first / 255;
    List<double> channel(double from, double to) {
      final slope = (to - from) / (1 - first);
      return [slope, 0, 0, 0, (from - slope * first) * 255];
    }

    return ColorFilter.matrix(<double>[
      ...channel(cold.r, hot.r),
      ...channel(cold.g, hot.g),
      ...channel(cold.b, hot.b),
      hot.a, 0, 0, 0, 0, //
    ]);
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.cold != cold ||
        oldDelegate.hot != hot ||
        oldDelegate.source != source ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
