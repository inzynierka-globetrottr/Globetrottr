import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_painter.dart';

class FogLayer extends StatelessWidget {
  final List<List<LatLng>> readyHoles;

  const FogLayer({super.key, required this.readyHoles});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return SizedBox.expand(
      child: CustomPaint(
        painter: FogPainter(holes: readyHoles, camera: camera),
      ),
    );
  }
}
