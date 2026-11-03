import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:latlong2/latlong.dart';

/// A still map of a quest: its route as a line, or its points numbered in
/// the order they are visited. Visited points are filled.
class QuestMapPreview extends StatelessWidget {
  const QuestMapPreview({super.key, required this.quest});

  final Quest quest;

  static const _height = 160.0;
  static const _radius = 16.0;
  static const _point = 24.0;
  static const _routeWidth = 5.0;
  static const _maxZoom = 16.0;

  List<LatLng> get _points => [
    for (final waypoint in quest.waypoints) waypoint.point,
    if (quest.waypoints.isEmpty && quest.location != null) quest.location!,
  ];

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final radius = BorderRadius.circular(_radius);
    return SizedBox(
      height: _height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: _maxZoom,
                initialCameraFit: points.length > 1
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(_point * 0.75),
                        maxZoom: _maxZoom,
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const AppTileLayer(),
                if (quest.isRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: palette.accent,
                        strokeWidth: _routeWidth,
                      ),
                    ],
                  )
                else
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < quest.waypoints.length; i++)
                        Marker(
                          point: quest.waypoints[i].point,
                          width: _point,
                          height: _point,
                          child: _PointBadge(
                            number: i + 1,
                            visited: quest.waypoints[i].visited,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            IgnorePointer(
              child: NeuInsetShadow(
                shadows: context.shadows.inset(NeoDepth.xs),
                borderRadius: radius,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  const _PointBadge({required this.number, required this.visited});

  final int number;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visited ? palette.accent : palette.background,
        border: Border.all(color: palette.accent, width: 2),
        boxShadow: [for (final s in context.shadows.marker) s.toBoxShadow()],
      ),
      child: Center(
        child: Text(
          '$number',
          style: context.typography.captionStrong.copyWith(
            color: visited ? palette.onAccent : palette.accent,
          ),
        ),
      ),
    );
  }
}
