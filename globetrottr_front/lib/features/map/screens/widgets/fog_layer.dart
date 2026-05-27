import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FogLayer extends StatelessWidget {
  const FogLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: const [
            LatLng(90.0, -180.0),
            LatLng(-90.0, -180.0),
            LatLng(-90.0, 180.0),
            LatLng(90.0, 180.0),
          ],
          isFilled: true,
          color: Colors.black.withValues(alpha: 0.75),
          borderStrokeWidth: 0.0,
        ),
      ],
    );
  }
}
