import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/core/utils/fog_holepuncher.dart';

class FogLayer extends StatelessWidget {
  // TODO: Refactor parameter to receive pre-computed hole points (e.g., List<List<LatLng>> readyHoles)
  // instead of raw coordinates, decoupling the UI from geometry generation.
  final LatLng? playerPosition;
  final double visionRadiusInMeters;

  const FogLayer({
    super.key,
    required this.playerPosition,
    this.visionRadiusInMeters = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Move this trigonometric calculation out of the build() method, this is here for debug purposes.
    // Hole generation should be handled by the business logic layer (LocationNotifier / FogNotifier)
    // to prevent heavy computations on the UI thread during frequent GPS updates.
    final holes = FogHolepuncher.getHoleCoordinates(
      playerPosition: playerPosition,
      visionRadiusInMeters: visionRadiusInMeters,
    );

    return PolygonLayer(
      polygons: [
        Polygon(
          points: const [
            LatLng(85.0, -180.0),
            LatLng(-85.0, -180.0),
            LatLng(-85.0, 180.0),
            LatLng(85.0, 180.0),
          ],
          holePointsList: holes,
          isFilled: true,
          color: Colors.black.withValues(alpha: 0.75),
          borderStrokeWidth: 0.0,
        ),
      ],
    );
  }
}
