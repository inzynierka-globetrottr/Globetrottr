import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_painter.dart';

/// The user's heatmap. Place it among the children of a `FlutterMap`; while
/// [source] is null nothing is drawn.
class HeatmapLayer extends StatelessWidget {
  const HeatmapLayer({super.key, this.source});

  final HeatTileSource? source;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    source?.ensureVisible(camera);
    final palette = context.palette;

    return SizedBox.expand(
      child: CustomPaint(
        painter: HeatmapPainter(
          camera: camera,
          cold: palette.heatCold,
          hot: palette.heatHot,
          source: source,
        ),
      ),
    );
  }
}
