import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/data/heat_store.dart';

/// The tile source of the heatmap: the fog's, fed with session counts.
typedef HeatTileSource = TileLayerSource<HeatStore>;
