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

  /// Regions by id, without their boundaries.
  Future<List<Region>> findRegionsByIds(Iterable<int> ids);

  /// Whether [region]'s boundary contains the point; the boundary is read
  /// on demand, since lookups return regions without it.
  Future<bool> regionContains(Region region, double lat, double lon);

  /// True once after the bundled database replaced an older local copy.
  Future<bool> consumeVersionChange();

  /// Installed country files: ISO code to version.
  Future<Map<String, int>> installedPacks();

  /// Copies the regions of the country file at [packPath], replacing an
  /// earlier version of it.
  Future<void> installPack(String country, int version, String packPath);
}
