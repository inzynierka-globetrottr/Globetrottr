import 'package:globetrottr_front/features/regions/data/region.dart';

abstract interface class RegionStorage {
  Future<void> init();
  Future<void> close();

  Future<Region?> findRegionById(int id);
  Future<List<Region>> findChildren(int parentId);
  Future<List<Region>> findRegionsByPoint({
    required double lat,
    required double lon,
  });
  Future<List<Region>> findRegionsInBBox({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  });
  Future<List<Region>> getAncestorChain(int regionId);
  Future<void> insertRegions(Iterable<Region> regions);
}
