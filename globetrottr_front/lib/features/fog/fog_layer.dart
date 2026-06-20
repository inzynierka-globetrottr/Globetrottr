import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_painter.dart';

class FogLayer extends StatelessWidget {
  final List<List<LatLng>> readyHoles;
  final int holesRevision;

  const FogLayer({
    super.key, 
    required this.readyHoles,
    this.holesRevision = 0
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return SizedBox.expand(
      child: CustomPaint(
        painter: FogPainter(
          holes: readyHoles, 
          camera: camera,
          holesRevision: holesRevision
        ),
      ),
    );
  }
}
