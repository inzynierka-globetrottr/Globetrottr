import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_cell_areas.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../support/region_geometry_encoder.dart';

const _tile = FogTileId(15, 18300, 11116);

double _lng(double worldX) => FogMercator.xToLng(worldX, 15);
double _lat(double worldY) => FogMercator.yToLat(worldY, 15);

final _west = _lng(_tile.x * 256.0);
final _mid = _lng(_tile.x * 256.0 + 128);
final _east = _lng((_tile.x + 1) * 256.0);
final _north = _lat(_tile.y * 256.0);
final _south = _lat((_tile.y + 1) * 256.0);

Region _area(
  int id,
  int? parent,
  RegionType type,
  double areaKm2, {
  required double minLon,
  required double maxLon,
  double? minLat,
  double? maxLat,
  String? code,
}) {
  final south = minLat ?? _south - 0.01;
  final north = maxLat ?? _north + 0.01;
  return Region(
    id: id,
    parentId: parent,
    name: 'r$id',
    type: type,
    code: code,
    totalAreaKm2: areaKm2,
    minLat: south,
    maxLat: north,
    minLon: minLon,
    maxLon: maxLon,
    geometry: encodeRegionGeometry(
      rectangle(minLon: minLon, minLat: south, maxLon: maxLon, maxLat: north),
    ),
  );
}

/// Country 501 (CZ) > state 502 > county 503 > cities 504 (west half of
/// [_tile]) and 505 (east half), plus 506, an unrelated region over the
/// tile's centre.
final _border = [
  _area(
    501,
    null,
    RegionType.country,
    78000,
    minLon: 20,
    maxLon: 22,
    minLat: 49,
    maxLat: 51,
    code: 'CZ',
  ),
  _area(502, 501, RegionType.state, 5000, minLon: 20.5, maxLon: 21.5),
  _area(503, 502, RegionType.county, 900, minLon: 20.9, maxLon: 21.2),
  _area(504, 503, RegionType.city, 10, minLon: _west - 0.01, maxLon: _mid),
  _area(505, 503, RegionType.city, 10, minLon: _mid, maxLon: _east + 0.01),
  _area(
    506,
    null,
    RegionType.state,
    6000,
    minLon: _mid - 0.001,
    maxLon: _mid + 0.01,
  ),
];

FogCellAreas _cells(bool Function(int cx, int cy) covered) {
  final values = Float32List(FogCellAreas.count);
  for (var cy = 0; cy < FogCellAreas.side; cy++) {
    for (var cx = 0; cx < FogCellAreas.side; cx++) {
      if (covered(cx, cy)) values[cy * FogCellAreas.side + cx] = 1;
    }
  }
  return FogCellAreas(values);
}

class _CountingRegions implements RegionStorage {
  _CountingRegions(this._inner);

  final RegionStorage _inner;
  int chains = 0;

  @override
  Future<List<Region>> getAncestorChain(int regionId) {
    chains++;
    return _inner.getAncestorChain(regionId);
  }

  @override
  Future<void> init() => _inner.init();

  @override
  Future<void> close() => _inner.close();

  @override
  Future<Region?> findRegionById(int id) => _inner.findRegionById(id);

  @override
  Future<List<Region>> findChildren(int parentId) =>
      _inner.findChildren(parentId);

  @override
  Future<List<Region>> findRegionsByPoint({
    required double lat,
    required double lon,
  }) => _inner.findRegionsByPoint(lat: lat, lon: lon);

  @override
  Future<List<Region>> findRegionsInBBox({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) => _inner.findRegionsInBBox(
    minLat: minLat,
    minLon: minLon,
    maxLat: maxLat,
    maxLon: maxLon,
  );

  @override
  Future<void> insertRegions(Iterable<Region> regions) =>
      _inner.insertRegions(regions);

  @override
  Future<bool> consumeVersionChange() => _inner.consumeVersionChange();

  @override
  Future<Map<String, int>> installedPacks() => _inner.installedPacks();

  @override
  Future<void> installPack(String country, int version, String packPath) =>
      _inner.installPack(country, version, packPath);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('StatisticsTracker', () {
    late Directory tempDir;
    late RegionStorage regionStorage;
    late StatisticsStorage statsStorage;
    late StatisticsTracker tracker;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stats_tracker_test_');
      regionStorage = SqfliteRegionStorage(
        path: '${tempDir.path}/regions.db',
      );
      await regionStorage.init();

      statsStorage = SqfliteStatisticsStorage(path: '${tempDir.path}/stats.db');
      await statsStorage.init();

      tracker = StatisticsTracker(
        regionStorage: regionStorage,
        statisticsStorage: statsStorage,
      );

      // Seed Poland -> Małopolska -> Kraków
      await regionStorage.insertRegions([
        const Region(
          id: 1,
          parentId: null,
          name: 'Polska',
          type: RegionType.country,
          code: 'PL',
          totalAreaKm2: 312696.0,
          minLat: 49.0,
          maxLat: 55.0,
          minLon: 14.0,
          maxLon: 24.5,
        ),
        const Region(
          id: 10,
          parentId: 1,
          name: 'Małopolskie',
          type: RegionType.state,
          code: null,
          totalAreaKm2: 15183.0,
          minLat: 49.1,
          maxLat: 50.5,
          minLon: 19.0,
          maxLon: 21.4,
        ),
        const Region(
          id: 100,
          parentId: 10,
          name: 'Kraków',
          type: RegionType.city,
          code: null,
          totalAreaKm2: 326.8,
          minLat: 49.95,
          maxLat: 50.15,
          minLon: 19.80,
          maxLon: 20.20,
        ),
      ]);
    });

    tearDown(() async {
      await regionStorage.close();
      await statsStorage.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'onTilesCommitted attributes area to city and parent hierarchy',
      () async {
        // Kraków center is around lat 50.06, lon 19.94
        // Web Mercator tile at z=15 for Kraków center:
        // x = ((19.94 + 180) / 360 * 32768).floor() = 18199
        // lat 50.06 -> y ≈ 11116
        const tileId = FogTileId(15, 18199, 11116);

        final now = DateTime(2026, 11, 3, 12);
        await tracker.onTilesCommitted(
          const [TileAreaDelta(id: tileId, areaDeltaM2: 50000.0)],
          now: now,
        );

        // Verify City stats (Kraków)
        final cityStats = await statsStorage.getRegionStats(100);
        expect(cityStats, isNotNull);
        expect(cityStats!.discoveredAreaM2, 50000.0);
        // 50,000 m2 = 0.05 km2 / 326.8 km2 * 100 ≈ 0.0153%
        expect(cityStats.discoveryPercentage, closeTo(0.0153, 0.001));

        // Verify State stats (Małopolskie)
        final stateStats = await statsStorage.getRegionStats(10);
        expect(stateStats, isNotNull);
        expect(stateStats!.discoveredAreaM2, 50000.0);

        // Verify Country stats (Polska)
        final countryStats = await statsStorage.getRegionStats(1);
        expect(countryStats, isNotNull);
        expect(countryStats!.discoveredAreaM2, 50000.0);

        // Verify Daily ledger
        final daily = await statsStorage.getDailyStats('2026-11-03');
        expect(daily, isNotNull);
        expect(daily!.newAreaM2, 50000.0);
      },
    );

    test(
      'recordTripSession updates daily distance',
      () async {
        final now = DateTime(2026, 11, 3, 14);

        await tracker.recordTripSession(
          distanceM: 3500.0,
          durationSeconds: 1800,
          activityType: 'walk',
          maxAltitudeM: 250.0,
          now: now,
        );

        final daily = await statsStorage.getDailyStats('2026-11-03');
        expect(daily, isNotNull);
        expect(daily!.distanceM, 3500.0);
        expect(daily.walkDistanceM, 3500.0);
        expect(daily.durationSeconds, 1800);

        final maxAlt = await statsStorage.getRecord('max_altitude');
        expect(maxAlt, 250.0);
      },
    );

    test(
      'recordRecordingDay on consecutive days makes a two-day streak',
      () async {
        await tracker.recordRecordingDay(now: DateTime(2026, 11, 3, 9));
        await tracker.recordRecordingDay(now: DateTime(2026, 11, 4, 9));

        final streak = await statsStorage.loadStreakStats();
        expect(streak.currentRecordingStreak, 2);
        expect(streak.lastRecordingDate, '2026-11-04');
      },
    );

    test('recordRecordingDay twice on one day counts one day', () async {
      await tracker.recordRecordingDay(now: DateTime(2026, 11, 3, 9));
      await tracker.recordRecordingDay(now: DateTime(2026, 11, 3, 18));

      final streak = await statsStorage.loadStreakStats();
      expect(streak.currentRecordingStreak, 1);
    });

    group('cells and borders', () {
      setUp(() => regionStorage.insertRegions(_border));

      test('a border tile is split by cell', () async {
        await tracker.onTilesCommitted([
          TileAreaDelta(
            id: _tile,
            areaDeltaM2: 128,
            cells: _cells((cx, cy) => cx < 8),
          ),
        ]);

        expect((await statsStorage.getRegionStats(504))?.discoveredAreaM2, 128);
        expect(await statsStorage.getRegionStats(505), isNull);
        expect((await statsStorage.getRegionStats(503))?.discoveredAreaM2, 128);
      });

      test('first and cached commits credit the same regions', () async {
        final delta = TileAreaDelta(
          id: _tile,
          areaDeltaM2: 4,
          cells: _cells((cx, cy) => cx == 0 && cy < 4),
        );

        await tracker.onTilesCommitted([delta]);
        await tracker.onTilesCommitted([delta]);

        expect((await statsStorage.getRegionStats(504))?.discoveredAreaM2, 8);
        expect((await statsStorage.getRegionStats(501))?.discoveredAreaM2, 8);
        expect(await statsStorage.getRegionStats(506), isNull);
      });

      test('a rebuild splits border tiles by their stored cells', () async {
        final asked = <FogTileId>[];
        await tracker.rebuildFromFogTiles(
          const [TileAreaDelta(id: _tile, areaDeltaM2: 128)],
          loadCells: (ids) async {
            asked.addAll(ids);
            return {_tile: _cells((cx, cy) => cx >= 8)};
          },
        );

        expect(asked, [_tile]);
        expect((await statsStorage.getRegionStats(505))?.discoveredAreaM2, 128);
        expect(await statsStorage.getRegionStats(504), isNull);
      });

      test('a missing country file is requested once per country', () async {
        final requested = <String>[];
        final packTracker = StatisticsTracker(
          regionStorage: regionStorage,
          statisticsStorage: statsStorage,
          onMissingPack: requested.add,
        );
        final delta = TileAreaDelta(
          id: _tile,
          areaDeltaM2: 4,
          cells: _cells((cx, cy) => cx == 0 && cy < 4),
        );

        await packTracker.onTilesCommitted([delta]);
        await packTracker.onTilesCommitted([delta]);

        expect(requested, ['CZ']);
      });
    });

    test('a city as large as its county is the leaf', () async {
      await regionStorage.insertRegions([
        _area(
          701,
          1,
          RegionType.county,
          40,
          minLon: _west - 0.05,
          maxLon: _east + 0.05,
        ),
        _area(
          702,
          701,
          RegionType.city,
          40,
          minLon: _west - 0.05,
          maxLon: _east + 0.05,
        ),
        _area(
          703,
          1,
          RegionType.county,
          30,
          minLon: _west - 0.06,
          maxLon: _east + 0.06,
        ),
      ]);

      await tracker.onTilesCommitted(const [
        TileAreaDelta(id: _tile, areaDeltaM2: 300),
      ]);

      expect((await statsStorage.getRegionStats(702))?.discoveredAreaM2, 300);
      expect((await statsStorage.getRegionStats(701))?.discoveredAreaM2, 300);
      expect(await statsStorage.getRegionStats(703), isNull);
    });

    test('an interior tile goes whole to one city', () async {
      await regionStorage.insertRegions([
        _area(
          601,
          1,
          RegionType.city,
          50,
          minLon: _west - 0.05,
          maxLon: _east + 0.05,
        ),
      ]);

      await tracker.onTilesCommitted(const [
        TileAreaDelta(id: _tile, areaDeltaM2: 300),
      ]);

      expect((await statsStorage.getRegionStats(601))?.discoveredAreaM2, 300);
      expect((await statsStorage.getRegionStats(1))?.discoveredAreaM2, 300);
    });

    test('tiles outside every region still count as daily new area', () async {
      await tracker.onTilesCommitted(const [
        TileAreaDelta(id: FogTileId(15, 100, 100), areaDeltaM2: 70),
      ], now: DateTime(2026, 11, 3, 12));

      expect(await statsStorage.getAllRegionStats(), isEmpty);
      expect((await statsStorage.getDailyStats('2026-11-03'))?.newAreaM2, 70);
    });

    test('rebuild replaces region stats', () async {
      await statsStorage.saveRegionStats(const [
        UserRegionStats(
          regionId: 999,
          discoveredAreaM2: 5,
          discoveryPercentage: 1,
        ),
        UserRegionStats(
          regionId: 100,
          discoveredAreaM2: 1,
          discoveryPercentage: 0,
          firstVisitMs: 1000,
          lastVisitMs: 2000,
        ),
      ]);

      await tracker.rebuildFromFogTiles(const [
        TileAreaDelta(id: FogTileId(15, 18199, 11116), areaDeltaM2: 40000),
      ]);

      expect(await statsStorage.getRegionStats(999), isNull);
      final krakow = await statsStorage.getRegionStats(100);
      expect(krakow?.discoveredAreaM2, 40000);
      expect(krakow?.firstVisitMs, 1000);
    });

    test('rebuild resolves each leaf once', () async {
      final counting = _CountingRegions(regionStorage);
      final rebuildTracker = StatisticsTracker(
        regionStorage: counting,
        statisticsStorage: statsStorage,
      );

      await rebuildTracker.rebuildFromFogTiles([
        for (var i = 0; i < 500; i++)
          TileAreaDelta(
            id: FogTileId(15, 18192 + i % 25, 11094 + i ~/ 25),
            areaDeltaM2: 1,
          ),
      ]);

      expect(counting.chains, 1);
    });

    test(
      'rebuildFromFogTiles recalculates stats from an entire set of fog tiles',
      () async {
        const tile1 = FogTileId(15, 18199, 11116); // Kraków
        const tile2 = FogTileId(15, 18200, 11116); // Kraków adjacent tile

        const tiles = [
          TileAreaDelta(id: tile1, areaDeltaM2: 40000.0),
          TileAreaDelta(id: tile2, areaDeltaM2: 60000.0),
        ];

        await tracker.rebuildFromFogTiles(tiles);

        final cityStats = await statsStorage.getRegionStats(100);
        expect(cityStats, isNotNull);
        expect(cityStats!.discoveredAreaM2, 100000.0);
        // 100,000 m2 = 0.1 km2 / 326.8 km2 * 100 ≈ 0.0306%
        expect(cityStats.discoveryPercentage, closeTo(0.0306, 0.001));

        final stateStats = await statsStorage.getRegionStats(10);
        expect(stateStats, isNotNull);
        expect(stateStats!.discoveredAreaM2, 100000.0);

        final bestDay = await statsStorage.getBestDayStats();
        expect(bestDay, isNull);

        final areaRecord = await statsStorage.getRecord('area');
        expect(areaRecord, isNull);
      },
    );
  });
}
