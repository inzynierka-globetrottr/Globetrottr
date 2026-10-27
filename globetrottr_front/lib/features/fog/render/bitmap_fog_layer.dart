import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

/// The user's own fog, drawn from bitmap tiles. Place it among the children
/// of a `FlutterMap`. While [source] is null the whole map is fogged.
class BitmapFogLayer extends StatelessWidget {
  const BitmapFogLayer({
    super.key,
    this.source,
    this.options = BitmapFogPainter.defaultOptions,
    this.liveCenter,
  });

  final FogTileSource? source;
  final FogRenderOptions options;
  final LatLng? liveCenter;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    source?.ensureVisible(camera);

    return SizedBox.expand(
      child: CustomPaint(
        painter: BitmapFogPainter(
          camera: camera,
          source: source,
          options: options,
          liveCenter: liveCenter,
        ),
      ),
    );
  }
}
