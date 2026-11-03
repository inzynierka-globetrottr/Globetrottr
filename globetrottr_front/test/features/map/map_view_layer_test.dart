import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/render/fog_view_layer.dart';
import 'package:globetrottr_front/features/heatmap/render/heatmap_view_layer.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_view_layer.dart';

void main() {
  test('every view that can be chosen has its own layer', () {
    for (final view in MapView.values.where((v) => v.isAvailable)) {
      expect(MapViewLayer.layers, contains(view), reason: '$view');
    }
  });

  test('the fog and the heatmap draw their own layers', () {
    expect(MapViewLayer.layers[MapView.fog], isA<FogViewLayer>());
    expect(MapViewLayer.layers[MapView.heatmap], isA<HeatmapViewLayer>());
  });
}
