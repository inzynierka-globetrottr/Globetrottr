import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_painter.dart';

// TODO(fog): polygon fog kept only for friends' fog; remove together with
// FogPainter once the friend map uses BitmapFogLayer.
class FogLayer extends StatelessWidget {
  final List<List<LatLng>> readyHoles;
  final int holesRevision;

  const FogLayer({
    super.key,
    required this.readyHoles,
    required this.holesRevision,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return SizedBox.expand(
      child: CustomPaint(
        painter: FogPainter(
          holes: readyHoles,
          camera: camera,
          holesRevision: holesRevision,
        ),
      ),
    );
  }
}
