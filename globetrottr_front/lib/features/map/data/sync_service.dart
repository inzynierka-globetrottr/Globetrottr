import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_sync_payload.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

class SyncService {
  SyncService(this._client, this._mapStorage, {this.statistics});

  final ApiClient _client;
  final MapStorage _mapStorage;
  final StatisticsSyncPayloadBuilder? statistics;

  // TODO(fog): the backend still builds its own fog from these points. Once it
  // accepts tiles, also upload the tiles changed since the last synced rev.
  Future<bool> syncPendingPoints() async {
    final points = await _mapStorage.getPendingPoints();

    if (points.isEmpty) return true;

    try {
      Map<String, Object?>? statsPayload;
      try {
        statsPayload = await statistics?.build();
      } catch (e) {
        debugPrint('Could not build statistics sync payload: $e');
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
    statistics: StatisticsSyncPayloadBuilder(
      statistics: ref.read(statisticsStorageProvider),
      regions: ref.read(regionStorageProvider),
      totalAreaM2: () =>
          ref.read(fogProvider).asData?.value.store.totalAreaM2 ?? 0,
      now: ref.read(clockProvider),
    ),
  ),
);
