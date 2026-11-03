import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';

/// The route of the active quest on the map, when it is a route.
class QuestRouteLayer extends ConsumerWidget {
  const QuestRouteLayer({super.key});

  static const _width = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = ref.watch(activeQuestProvider);
    if (quest == null || !quest.isRoute || quest.waypoints.length < 2) {
      return const SizedBox.shrink();
    }
    return PolylineLayer(
      polylines: [
        Polyline(
          points: [for (final waypoint in quest.waypoints) waypoint.point],
          color: context.palette.accent,
          strokeWidth: _width,
        ),
      ],
    );
  }
}
