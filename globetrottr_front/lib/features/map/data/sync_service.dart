import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';

class SyncService {
  final ApiClient _client;
  SyncService(this._client);

  Future<void> syncPendingPoints() async {
    final points = await MapStorage().getPendingPoints();

    if (points.isEmpty) return;

    try {
      await _client.post(
        '/api/map/sync',
        body: {'points': points.map((p) => p.toMap()).toList()},
      );
      await MapStorage().deletePendingPointsByIds(points.map((p) => p.id!).toList());
      print('Local DB was cleared');
    } catch (e) {
      print('Sync Error: $e');
    }
  }
}

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.read(apiClientProvider)),
);
