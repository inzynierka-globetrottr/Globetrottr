import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store_models.dart';

/// A derived layer of the track log kept as 8-bit tiles in the fog's tile
/// pyramid (the fog itself, the heatmap). `FogTileSource` turns any of them
/// into images.
abstract interface class FogTileLayer {
  /// Most detailed level of the pyramid.
  int get baseZoom;

  Stream<FogChange> get changes;

  /// Loads the tiles of [range] so [peek] can answer synchronously.
  Future<void> prepare(FogTileRange range);

  /// The decoded tile if it is cached, without any I/O.
  FogMask? peek(FogTileId id);

  bool isKnownAbsent(FogTileId id);
}

/// A layer that draws its newest points over the tile images until they are
/// written into them (the fog's trail).
abstract interface class TrailedTileLayer implements FogTileLayer {
  /// The images now hold everything drawn up to trail segment [upToId], so
  /// it no longer needs to be drawn over them.
  void forgetTrail(int upToId);
}
