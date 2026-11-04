import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_cell_areas.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';

class TileAreaDelta {
  const TileAreaDelta({
    required this.id,
    required this.areaDeltaM2,
    this.cells,
  });

  final FogTileId id;
  final double areaDeltaM2;

  /// Where in the tile the area lies; without it a border tile is credited
  /// to the region at its centre.
  final FogCellAreas? cells;
}

/// Attributes revealed area to regions. A tile whose centre and corners lie
/// in one leaf region goes to it whole; any other tile is split by the
/// centres of its 16 x 16-pixel cells. The leaf's ancestors get the same
/// area, so every tile counts once per level.
class StatisticsTracker {
  StatisticsTracker({
    required this.regionStorage,
    required this.statisticsStorage,
    this.streakService = const StreakService(),
    this.onUpdated,
    this.onMissingPack,
  });

  final RegionStorage regionStorage;
  final StatisticsStorage statisticsStorage;
  final StreakService streakService;
  final void Function()? onUpdated;

  /// Asks for the cities of a country, once per country.
  final void Function(String countryCode)? onMissingPack;

  final SerialQueue _queue = SerialQueue();
  final Set<String> _requestedPacks = {};

  // Values of the tile-to-region cache besides a leaf id.
  static const int _border = 0;
  static const int _nowhere = -1;

  Future<void> onTilesCommitted(
    Iterable<TileAreaDelta> tiles, {
    DateTime? now,
  }) {
    return _queue.run(() => _processTilesCommitted(tiles, now: now));
  }

  Future<void> _processTilesCommitted(
    Iterable<TileAreaDelta> tiles, {
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final todayStr = _formatDate(moment);
    var totalNewArea = 0.0;
    final attribution = _Attribution();

    for (final tile in tiles) {
      if (tile.areaDeltaM2 <= 0) continue;
      totalNewArea += tile.areaDeltaM2;
      await _attribute(tile, attribution);
    }

    if (attribution.areas.isNotEmpty) {
      final nowMs = moment.millisecondsSinceEpoch;
      final updated = <UserRegionStats>[];
      for (final MapEntry(key: regionId, value: delta)
          in attribution.areas.entries) {
        final existing = await statisticsStorage.getRegionStats(regionId);
        final area = (existing?.discoveredAreaM2 ?? 0.0) + delta;
        updated.add(
          UserRegionStats(
            regionId: regionId,
            discoveredAreaM2: area,
            discoveryPercentage: _percentage(
              area,
              attribution.regions[regionId]!,
            ),
            firstVisitMs: existing?.firstVisitMs ?? nowMs,
            lastVisitMs: nowMs,
            visitsCount: (existing?.visitsCount ?? 0) + 1,
            timeSpentSeconds: existing?.timeSpentSeconds ?? 0,
          ),
        );
      }
      await statisticsStorage.saveRegionStats(updated);
    }

    if (totalNewArea > 0) {
      final daily =
          (await statisticsStorage.getDailyStats(todayStr)) ??
          DailyExplorationStats(date: todayStr);
      await statisticsStorage.saveDailyStats(
        daily.copyWith(newAreaM2: daily.newAreaM2 + totalNewArea),
      );
    }

    if (attribution.areas.isNotEmpty || totalNewArea > 0) {
      onUpdated?.call();
    }
  }

  /// Replaces the region statistics with those of [tiles], keeping the
  /// visit dates of regions that are still reached. [loadCells] reads the
  /// stored cells of the border tiles, in batches.
  Future<void> rebuildFromFogTiles(
    Iterable<TileAreaDelta> tiles, {
    Future<Map<FogTileId, FogCellAreas>> Function(List<FogTileId> ids)?
    loadCells,
    bool keepVisits = true,
    bool resetTileCache = false,
  }) {
    return _queue.run(() async {
      if (resetTileCache) await statisticsStorage.clearTileRegionCache();
      await _processRebuildFromFogTiles(tiles, loadCells, keepVisits);
    });
  }

  static const _cellBatch = 500;

  Future<void> _processRebuildFromFogTiles(
    Iterable<TileAreaDelta> tiles,
    Future<Map<FogTileId, FogCellAreas>> Function(List<FogTileId> ids)?
    loadCells,
    bool keepVisits,
  ) async {
    final attribution = _Attribution();
    final border = <TileAreaDelta>[];
    for (final tile in tiles) {
      if (tile.areaDeltaM2 <= 0) continue;
      final leafId = await _tileLeaf(tile.id);
      if (leafId == _border) {
        border.add(tile);
      } else if (leafId != _nowhere) {
        attribution.credit(await _chain(leafId, attribution), tile.areaDeltaM2);
      }
    }
    for (var start = 0; start < border.length; start += _cellBatch) {
      final batch = border.sublist(
        start,
        (start + _cellBatch).clamp(0, border.length),
      );
      final cells = loadCells == null
          ? const <FogTileId, FogCellAreas>{}
          : await loadCells([for (final t in batch) t.id]);
      for (final tile in batch) {
        await _attributeBorder(tile, cells[tile.id] ?? tile.cells, attribution);
      }
    }

    final existing = {
      if (keepVisits)
        for (final s in await statisticsStorage.getAllRegionStats())
          s.regionId: s,
    };
    await statisticsStorage.replaceRegionStats([
      for (final MapEntry(key: regionId, value: area)
          in attribution.areas.entries)
        UserRegionStats(
          regionId: regionId,
          discoveredAreaM2: area,
          discoveryPercentage: _percentage(
            area,
            attribution.regions[regionId]!,
          ),
          firstVisitMs: existing[regionId]?.firstVisitMs,
          lastVisitMs: existing[regionId]?.lastVisitMs,
          visitsCount: existing[regionId]?.visitsCount ?? 1,
          timeSpentSeconds: existing[regionId]?.timeSpentSeconds ?? 0,
        ),
    ]);
    onUpdated?.call();
  }

  Future<void> _attribute(TileAreaDelta tile, _Attribution into) async {
    final leafId = await _tileLeaf(tile.id);
    if (leafId == _nowhere) return;
    if (leafId != _border) {
      into.credit(await _chain(leafId, into), tile.areaDeltaM2);
      return;
    }
    await _attributeBorder(tile, tile.cells, into);
  }

  Future<void> _attributeBorder(
    TileAreaDelta tile,
    FogCellAreas? cells,
    _Attribution into,
  ) async {
    final candidates = await _candidates(tile.id);
    if (cells == null) {
      final (lat, lon) = _pixelLatLng(tile.id, 128, 128);
      final leaf = await _leafAt(candidates, lat, lon);
      if (leaf != null) {
        into.credit(await _chain(leaf.id, into), tile.areaDeltaM2);
      }
      return;
    }
    const half = FogCellAreas.pixelsPerCell / 2;
    for (var cy = 0; cy < FogCellAreas.side; cy++) {
      for (var cx = 0; cx < FogCellAreas.side; cx++) {
        final area = cells.values[cy * FogCellAreas.side + cx];
        if (area <= 0) continue;
        final (lat, lon) = _pixelLatLng(
          tile.id,
          cx * FogCellAreas.pixelsPerCell + half,
          cy * FogCellAreas.pixelsPerCell + half,
        );
        final leaf = await _leafAt(candidates, lat, lon);
        if (leaf != null) into.credit(await _chain(leaf.id, into), area);
      }
    }
  }

  /// The leaf region of a tile, [_border] when the tile crosses a border or
  /// [_nowhere] outside every region. Kept in the tile cache.
  Future<int> _tileLeaf(FogTileId id) async {
    final cached = await statisticsStorage.getCachedTileRegion(
      z: id.z,
      x: id.x,
      y: id.y,
    );
    if (cached != null) return cached;

    final candidates = await _candidates(id);
    final probes = <int?>[];
    for (final (px, py) in const [
      (128.0, 128.0),
      (0.5, 0.5),
      (255.5, 0.5),
      (0.5, 255.5),
      (255.5, 255.5),
    ]) {
      final (lat, lon) = _pixelLatLng(id, px, py);
      probes.add((await _leafAt(candidates, lat, lon))?.id);
    }
    final int value;
    if (probes.every((p) => p == null)) {
      value = _nowhere;
    } else if (probes.first != null && probes.every((p) => p == probes.first)) {
      value = probes.first!;
    } else {
      value = _border;
    }
    await statisticsStorage.cacheTileRegion(
      z: id.z,
      x: id.x,
      y: id.y,
      regionId: value,
    );
    return value;
  }

  Future<List<Region>> _candidates(FogTileId id) {
    final (north, west) = _pixelLatLng(id, 0, 0);
    final (south, east) = _pixelLatLng(id, 256, 256);
    return regionStorage.findRegionsInBBox(
      minLat: south,
      minLon: west,
      maxLat: north,
      maxLon: east,
    );
  }

  /// The smallest region containing the point; [candidates] come sorted by
  /// area.
  Future<Region?> _leafAt(
    List<Region> candidates,
    double lat,
    double lon,
  ) async {
    for (final region in candidates) {
      if (await regionStorage.regionContains(region, lat, lon)) return region;
    }
    return null;
  }

  Future<List<Region>> _chain(int leafId, _Attribution into) async {
    final known = into.chains[leafId];
    if (known != null) return known;
    final chain = await regionStorage.getAncestorChain(leafId);
    into.chains[leafId] = chain;
    for (final region in chain) {
      final code = region.code;
      if (region.type == RegionType.country &&
          code != null &&
          onMissingPack != null &&
          _requestedPacks.add(code)) {
        onMissingPack!(code);
      }
    }
    return chain;
  }

  static (double, double) _pixelLatLng(FogTileId id, double px, double py) => (
    FogMercator.yToLat(id.y * FogTileId.size + py, id.z),
    FogMercator.xToLng(id.x * FogTileId.size + px, id.z),
  );

  static double _percentage(double areaM2, Region region) {
    if (region.totalAreaKm2 <= 0) return 0;
    return ((areaM2 / 1000000.0) / region.totalAreaKm2 * 100.0).clamp(
      0.0,
      100.0,
    );
  }

  Future<void> recordTripSession({
    required double distanceM,
    required int durationSeconds,
    required String activityType,
    double? maxAltitudeM,
    DateTime? now,
  }) {
    return _queue.run(
      () => _processRecordTripSession(
        distanceM: distanceM,
        durationSeconds: durationSeconds,
        activityType: activityType,
        maxAltitudeM: maxAltitudeM,
        now: now,
      ),
    );
  }

  Future<void> _processRecordTripSession({
    required double distanceM,
    required int durationSeconds,
    required String activityType,
    double? maxAltitudeM,
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final todayStr = _formatDate(moment);

    final daily =
        (await statisticsStorage.getDailyStats(todayStr)) ??
        DailyExplorationStats(date: todayStr);

    var walkDelta = 0.0;
    var bikeDelta = 0.0;
    var runDelta = 0.0;
    var otherDelta = 0.0;

    switch (activityType.toLowerCase()) {
      case 'walk':
      case 'spacer':
        walkDelta = distanceM;
      case 'bike':
      case 'rower':
        bikeDelta = distanceM;
      case 'run':
      case 'bieg':
        runDelta = distanceM;
      default:
        otherDelta = distanceM;
    }

    await statisticsStorage.saveDailyStats(
      daily.copyWith(
        distanceM: daily.distanceM + distanceM,
        durationSeconds: daily.durationSeconds + durationSeconds,
        walkDistanceM: daily.walkDistanceM + walkDelta,
        bikeDistanceM: daily.bikeDistanceM + bikeDelta,
        runDistanceM: daily.runDistanceM + runDelta,
        otherDistanceM: daily.otherDistanceM + otherDelta,
      ),
    );

    if (maxAltitudeM != null) {
      await statisticsStorage.setRecordIfMax(
        'max_altitude',
        maxAltitudeM,
        timestampMs: moment.millisecondsSinceEpoch,
      );
    }

    await statisticsStorage.setRecordIfMax(
      'longest_route_distance',
      distanceM,
      timestampMs: moment.millisecondsSinceEpoch,
    );

    onUpdated?.call();
  }

  Future<void> recordRecordingDay({DateTime? now}) {
    return _queue.run(() async {
      final current = await statisticsStorage.loadStreakStats();
      final updated = streakService.recordRecordingDay(current, now: now);
      if (updated.lastRecordingDate == current.lastRecordingDate) return;
      await statisticsStorage.saveStreakStats(updated);
      onUpdated?.call();
    });
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Area per region gathered while attributing one batch of tiles, with the
/// lookups the batch has already made.
class _Attribution {
  final areas = <int, double>{};
  final regions = <int, Region>{};
  final chains = <int, List<Region>>{};

  void credit(List<Region> chain, double area) {
    for (final region in chain) {
      regions[region.id] = region;
      areas[region.id] = (areas[region.id] ?? 0.0) + area;
    }
  }
}
