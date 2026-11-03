import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_drawer.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_style.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';

/// Paints the heatmap: the [HeatStyle.backdrop] over the map, then the tile
/// images, already coloured by [style], added together so neighbouring tiles
/// leave no seam.
class HeatmapPainter extends CustomPainter {
  HeatmapPainter({required this.camera, required this.style, this.source})
    : super(repaint: source);

  final MapCamera camera;
  final HeatStyle style;
  final HeatTileSource? source;

  @override
  void paint(Canvas canvas, Size size) {
    final backdrop = style.backdrop;
    if (backdrop != null) canvas.drawColor(backdrop, BlendMode.srcOver);
    final source = this.source;
    if (source == null || !camera.isUsableForFog) return;
    final timer = Stopwatch()..start();
    canvas.saveLayer(Offset.zero & size, Paint());
    FogTileDrawer(camera).drawTiles(canvas, source);
    canvas.restore();
    source.stats.record(timer.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.source != source ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
