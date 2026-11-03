import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

class SyncService {
  final ApiClient _client;
  final MapStorage _mapStorage;
  final StatisticsStorage? _statsStorage;
  final Ref? _ref;

  SyncService(
    this._client,
    this._mapStorage, [
    this._statsStorage,
    this._ref,
  ]);

  Future<bool> syncPendingPoints() async {
    final points = await _mapStorage.getPendingPoints();

    if (points.isEmpty) return true;

    try {
      Map<String, Object?>? statsPayload;
      if (_statsStorage != null) {
        try {
          final streakStats = await _statsStorage.loadStreakStats();
          final regionStats = await _statsStorage.getAllRegionStats();

          var visitedCountries = 0;
          if (_ref != null) {
            try {
              final regionStorage = _ref.read(regionStorageProvider);
              for (final s in regionStats) {
                if (s.discoveredAreaM2 > 0) {
                  final reg = await regionStorage.findRegionById(s.regionId);
                  if (reg?.type == RegionType.country) {
                    visitedCountries++;
                  }
                }
              }
            } catch (_) {}
          }

          final totalKm2 =
              regionStats.fold<double>(
                0.0,
                (sum, r) => sum + r.discoveredAreaM2,
              ) /
              1000000.0;

          statsPayload = {
            'totalDiscoveredKm2': totalKm2,
            'visitedCountriesCount': visitedCountries,
            'currentStreak': streakStats.currentRecordingStreak,
            'appStreak': streakStats.currentOpenStreak,
            'regions': [
              for (final r in regionStats)
                if (r.discoveredAreaM2 > 0)
                  {
                    'regionId': r.regionId,
                    'discoveredAreaKm2': r.discoveredAreaM2 / 1000000.0,
                    'discoveryPercentage': r.discoveryPercentage,
                  },
            ],
          };
        } catch (e) {
          debugPrint('Could not build statistics sync payload: $e');
        }
      }

      await _client.post(
        '/api/map/sync',
        body: {
          'points': points.map((p) => p.toMap()).toList(),
          if (statsPayload != null) 'statistics': statsPayload,
        },
      );
      final lastSyncedId = points.map((p) => p.id!).reduce(math.max);
      await _mapStorage.deletePendingPointsUpTo(lastSyncedId);
      debugPrint('Local DB was cleared');
      return true;
    } catch (e) {
      debugPrint('Sync Error: $e');
      return false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.read(apiClientProvider),
    ref.read(mapStorageProvider),
    ref.read(statisticsStorageProvider),
    ref,
  ),
);
