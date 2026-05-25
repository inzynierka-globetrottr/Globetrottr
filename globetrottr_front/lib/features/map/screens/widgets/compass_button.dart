import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';

class CompassButton extends StatelessWidget {
  final MapController mapController;

  const CompassButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, snapshot) {
        final rotationDegrees = mapController.camera.rotation;

        if (rotationDegrees == 0.0) {
          return const SizedBox.shrink();
        }

        return NeuIconButton(
          onPressed: () {
            mapController.rotate(0.0);
          },
          child: Transform.rotate(
            angle: (-rotationDegrees - 45) * (math.pi / 180),
            child: const Icon(
              Icons.explore,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}