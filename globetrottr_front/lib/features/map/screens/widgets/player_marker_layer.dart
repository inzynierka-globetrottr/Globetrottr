import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/map/screens/widgets/player_marker.dart';

class PlayerMarkerLayer extends StatelessWidget {
  final LatLng position;

  const PlayerMarkerLayer({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: position,
          width: PlayerMarker.size,
          height: PlayerMarker.size,
          child: const PlayerMarker(),
        ),
      ],
    );
  }
}
