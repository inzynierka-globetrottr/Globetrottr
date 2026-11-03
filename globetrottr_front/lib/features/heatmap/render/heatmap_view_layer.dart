import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/heatmap/provider/heatmap_provider.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_style.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_layer.dart';

/// The heatmap view of the map. Building it opens the heatmap the first time
/// it is shown; it keeps counting from then on, because the provider stays
/// alive. Place it among the children of a `FlutterMap`.
class HeatmapViewLayer extends ConsumerWidget {
  const HeatmapViewLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HeatmapLayer(
      style: HeatStyle.of(context.palette),
      source: ref.watch(heatmapProvider).value,
    );
  }
}
