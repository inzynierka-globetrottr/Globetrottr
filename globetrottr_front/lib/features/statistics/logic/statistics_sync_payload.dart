import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';

/// The `statistics` part of a `/api/map/sync` request.
class StatisticsSyncPayloadBuilder {
  StatisticsSyncPayloadBuilder({
    required this.statistics,
    required this.regions,
    required this.totalAreaM2,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final StatisticsStorage statistics;
  final RegionStorage regions;

  /// Area of the whole fog; 0 when the fog is not open yet.
  final double Function() totalAreaM2;
  final DateTime Function() _now;

  Future<Map<String, Object?>> build() async {
    final streakStats = await statistics.loadStreakStats();
    final regionStats = await statistics.getAllRegionStats();

    var visitedCountries = 0;
    var countryTotalM2 = 0.0;
    final regionsPayload = <Map<String, Object?>>[];
    final discovered = regionStats.where((s) => s.discoveredAreaM2 > 0);
    final byId = {
      for (final r in await regions.findRegionsByIds(
        discovered.map((s) => s.regionId),
      ))
        r.id: r,
    };
    for (final s in discovered) {
      final region = byId[s.regionId];
      if (region?.type == RegionType.country) {
        visitedCountries++;
        countryTotalM2 += s.discoveredAreaM2;
      }
      regionsPayload.add({
        'regionId': s.regionId,
        'regionName': region?.name,
        'regionCode': region?.code,
        'discoveredAreaKm2': s.discoveredAreaM2 / 1000000.0,
        'discoveryPercentage': s.discoveryPercentage,
      });
    }

    final fogM2 = totalAreaM2();
    final now = _now();
    const streakService = StreakService();
    return {
      'totalDiscoveredKm2': (fogM2 > 0 ? fogM2 : countryTotalM2) / 1000000.0,
      'visitedCountriesCount': visitedCountries,
      'currentStreak': streakService.effectiveRecordingStreak(streakStats, now),
      'appStreak': streakService.effectiveOpenStreak(streakStats, now),
      'regions': regionsPayload,
    };
  }
}
