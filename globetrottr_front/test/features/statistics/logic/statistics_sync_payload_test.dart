import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_sync_payload.dart';

class _Statistics extends Fake implements StatisticsStorage {
  @override
  Future<UserStreakStats> loadStreakStats() async => const UserStreakStats(
    currentOpenStreak: 3,
    maxOpenStreak: 3,
    lastOpenDate: '2026-11-04',
    currentRecordingStreak: 2,
    maxRecordingStreak: 4,
    lastRecordingDate: '2026-11-03',
  );

  @override
  Future<List<UserRegionStats>> getAllRegionStats() async => const [
    UserRegionStats(
      regionId: 1,
      discoveredAreaM2: 2000000,
      discoveryPercentage: 0.00064,
    ),
    UserRegionStats(
      regionId: 100,
      discoveredAreaM2: 500000,
      discoveryPercentage: 0.153,
    ),
    UserRegionStats(regionId: 7, discoveredAreaM2: 0, discoveryPercentage: 0),
    UserRegionStats(
      regionId: 999,
      discoveredAreaM2: 1000,
      discoveryPercentage: 0,
    ),
  ];
}

Region _region(int id, String name, RegionType type, String? code) => Region(
  id: id,
  parentId: null,
  name: name,
  type: type,
  code: code,
  totalAreaKm2: 1,
  minLat: 0,
  maxLat: 1,
  minLon: 0,
  maxLon: 1,
);

class _Regions extends Fake implements RegionStorage {
  @override
  Future<Region?> findRegionById(int id) async => switch (id) {
    1 => _region(1, 'Polska', RegionType.country, 'PL'),
    100 => _region(100, 'Kraków', RegionType.city, null),
    _ => null,
  };
}

void main() {
  StatisticsSyncPayloadBuilder builder({required double totalAreaM2}) =>
      StatisticsSyncPayloadBuilder(
        statistics: _Statistics(),
        regions: _Regions(),
        totalAreaM2: () => totalAreaM2,
        now: () => DateTime(2026, 11, 4, 12),
      );

  test('the payload keeps the shape the backend reads', () async {
    final payload = await builder(totalAreaM2: 2500000).build();

    expect(payload, {
      'totalDiscoveredKm2': 2.5,
      'visitedCountriesCount': 1,
      'currentStreak': 2,
      'appStreak': 3,
      'regions': [
        {
          'regionId': 1,
          'regionName': 'Polska',
          'regionCode': 'PL',
          'discoveredAreaKm2': 2.0,
          'discoveryPercentage': 0.00064,
        },
        {
          'regionId': 100,
          'regionName': 'Kraków',
          'regionCode': null,
          'discoveredAreaKm2': 0.5,
          'discoveryPercentage': 0.153,
        },
        {
          'regionId': 999,
          'regionName': null,
          'regionCode': null,
          'discoveredAreaKm2': 0.001,
          'discoveryPercentage': 0.0,
        },
      ],
    });
  });

  test('without a fog total the countries add up the total', () async {
    final payload = await builder(totalAreaM2: 0).build();

    expect(payload['totalDiscoveredKm2'], 2.0);
  });
}
