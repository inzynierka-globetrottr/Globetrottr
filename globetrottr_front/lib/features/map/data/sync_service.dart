import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';

class SyncService {
  final ApiClient _client;
  final MapStorage _mapStorage;

  SyncService(this._client, this._mapStorage);

  // TODO(fog): the backend still builds its own fog from these points. Once it
  // accepts tiles, also upload the tiles changed since the last synced rev.
  Future<bool> syncPendingPoints() async {
    final points = await _mapStorage.getPendingPoints();

    if (points.isEmpty) return true;

    try {
      await _client.post(
        '/api/map/sync',
        body: {'points': points.map((p) => p.toMap()).toList()},
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
  (ref) =>
      SyncService(ref.read(apiClientProvider), ref.read(mapStorageProvider)),
);
