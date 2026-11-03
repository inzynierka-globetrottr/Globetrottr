import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/daily_exploration_stats.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';

class TileAreaDelta {
  final FogTileId id;
  final double areaDeltaM2;

  const TileAreaDelta({required this.id, required this.areaDeltaM2});
}

class StatisticsTracker {
  final RegionStorage regionStorage;
  final StatisticsStorage statisticsStorage;
  final StreakService streakService;
  final void Function()? onUpdated;
  final SerialQueue _queue = SerialQueue();

  StatisticsTracker({
    required this.regionStorage,
    required this.statisticsStorage,
    this.streakService = const StreakService(),
    this.onUpdated,
  });

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

    final regionAreaDeltas = <int, double>{};
    final resolvedRegions = <int, Region>{};

    for (final tile in tiles) {
      if (tile.areaDeltaM2 <= 0) continue;
      totalNewArea += tile.areaDeltaM2;

      final id = tile.id;
      var leafRegionId = await statisticsStorage.getCachedTileRegion(
        z: id.z,
        x: id.x,
        y: id.y,
      );

      List<Region> hierarchy;
      if (leafRegionId != null) {
        hierarchy = await regionStorage.getAncestorChain(leafRegionId);
      } else {
        final worldCenterX = (id.x + 0.5) * FogTileId.size;
        final worldCenterY = (id.y + 0.5) * FogTileId.size;
        final lon = FogMercator.xToLng(worldCenterX, id.z);
        final lat = FogMercator.yToLat(worldCenterY, id.z);

        hierarchy = await regionStorage.findRegionsByPoint(lat: lat, lon: lon);
        if (hierarchy.isNotEmpty) {
          leafRegionId = hierarchy.first.id;
          await statisticsStorage.cacheTileRegion(
            z: id.z,
            x: id.x,
            y: id.y,
            regionId: leafRegionId,
          );
        }
      }

      for (final region in hierarchy) {
        resolvedRegions[region.id] = region;
        regionAreaDeltas[region.id] =
            (regionAreaDeltas[region.id] ?? 0.0) + tile.areaDeltaM2;
      }
    }

    if (regionAreaDeltas.isNotEmpty) {
      final updatedStats = <UserRegionStats>[];
      final nowMs = moment.millisecondsSinceEpoch;

      for (final entry in regionAreaDeltas.entries) {
        final regionId = entry.key;
        final delta = entry.value;
        final region = resolvedRegions[regionId]!;

        final existing = await statisticsStorage.getRegionStats(regionId);
        final newArea = (existing?.discoveredAreaM2 ?? 0.0) + delta;
        final percentage = (newArea / 1000000.0) / region.totalAreaKm2 * 100.0;

        updatedStats.add(
          UserRegionStats(
            regionId: regionId,
            discoveredAreaM2: newArea,
            discoveryPercentage: percentage.clamp(0.0, 100.0),
            firstVisitMs: existing?.firstVisitMs ?? nowMs,
            lastVisitMs: nowMs,
            visitsCount: (existing?.visitsCount ?? 0) + 1,
            timeSpentSeconds: existing?.timeSpentSeconds ?? 0,
          ),
        );
      }

      await statisticsStorage.saveRegionStats(updatedStats);
    }

    if (totalNewArea > 0) {
      final daily =
          (await statisticsStorage.getDailyStats(todayStr)) ??
          DailyExplorationStats(date: todayStr);
      await statisticsStorage.saveDailyStats(
        daily.copyWith(
          newAreaM2: daily.newAreaM2 + totalNewArea,
        ),
      );
    }

    if (regionAreaDeltas.isNotEmpty || totalNewArea > 0) {
      onUpdated?.call();
    }
  }

  Future<void> rebuildFromFogTiles(Iterable<TileAreaDelta> tiles) {
    return _queue.run(() => _processRebuildFromFogTiles(tiles));
  }

  Future<void> _processRebuildFromFogTiles(
    Iterable<TileAreaDelta> tiles,
  ) async {
    final regionAreas = <int, double>{};
    final resolvedRegions = <int, Region>{};

    for (final tile in tiles) {
      if (tile.areaDeltaM2 <= 0) continue;
      final id = tile.id;

      var leafRegionId = await statisticsStorage.getCachedTileRegion(
        z: id.z,
        x: id.x,
        y: id.y,
      );

      List<Region> hierarchy;
      if (leafRegionId != null) {
        hierarchy = await regionStorage.getAncestorChain(leafRegionId);
      } else {
        final worldCenterX = (id.x + 0.5) * FogTileId.size;
        final worldCenterY = (id.y + 0.5) * FogTileId.size;
        final lon = FogMercator.xToLng(worldCenterX, id.z);
        final lat = FogMercator.yToLat(worldCenterY, id.z);

        hierarchy = await regionStorage.findRegionsByPoint(lat: lat, lon: lon);
        if (hierarchy.isNotEmpty) {
          leafRegionId = hierarchy.first.id;
          await statisticsStorage.cacheTileRegion(
            z: id.z,
            x: id.x,
            y: id.y,
            regionId: leafRegionId,
          );
        }
      }

      for (final region in hierarchy) {
        resolvedRegions[region.id] = region;
        regionAreas[region.id] =
            (regionAreas[region.id] ?? 0.0) + tile.areaDeltaM2;
      }
    }

    final updated = <UserRegionStats>[];
    for (final entry in regionAreas.entries) {
      final region = resolvedRegions[entry.key]!;
      final area = entry.value;
      final percentage = (area / 1000000.0) / region.totalAreaKm2 * 100.0;
      final existing = await statisticsStorage.getRegionStats(entry.key);
      updated.add(
        UserRegionStats(
          regionId: entry.key,
          discoveredAreaM2: area,
          discoveryPercentage: percentage.clamp(0.0, 100.0),
          firstVisitMs: existing?.firstVisitMs,
          lastVisitMs: existing?.lastVisitMs,
          visitsCount: existing?.visitsCount ?? 1,
          timeSpentSeconds: existing?.timeSpentSeconds ?? 0,
        ),
      );
    }

    await statisticsStorage.saveRegionStats(updated);
    onUpdated?.call();
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

    final currentStreaks = await statisticsStorage.loadStreakStats();
    final updatedStreaks = streakService.recordTripCompleted(
      currentStreaks,
      distanceM: distanceM,
      newAreaM2: 0,
      now: moment,
    );
    await statisticsStorage.saveStreakStats(updatedStreaks);

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

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
