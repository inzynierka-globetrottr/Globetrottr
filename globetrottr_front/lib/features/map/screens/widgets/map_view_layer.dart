import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/fog/render/fog_view_layer.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_view_layer.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';

/// Draws what the user discovered the way the chosen [MapView] shows it.
/// Place it among the children of a `FlutterMap`.
class MapViewLayer extends ConsumerWidget {
  const MapViewLayer({super.key});

  /// The layer of every view that has one. A new view adds its layer here;
  /// a view without one shows the fog.
  static const Map<MapView, Widget> layers = {
    MapView.fog: FogViewLayer(),
    MapView.heatmap: HeatmapViewLayer(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return layers[ref.watch(mapViewProvider)] ?? layers[MapView.fog]!;
  }
}
