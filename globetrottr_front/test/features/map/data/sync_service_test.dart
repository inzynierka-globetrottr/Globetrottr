import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_sync_payload.dart';
import 'package:http/http.dart' as http;

class _RecordingClient extends Fake implements ApiClient {
  Map<String, dynamic>? body;

  @override
  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    this.body = body;
    return http.Response('Sync complete', 200);
  }
}

class _Outbox extends Fake implements MapStorage {
  int? deletedUpTo;

  @override
  Future<List<PendingPoint>> getPendingPoints() async => [
    PendingPoint(
      id: 4,
      sessionId: 's',
      latitude: 50,
      longitude: 19.9,
      timestamp: 1000,
    ),
    PendingPoint(
      id: 9,
      sessionId: 's',
      latitude: 50.001,
      longitude: 19.9,
      timestamp: 2000,
    ),
  ];

  @override
  Future<void> deletePendingPointsUpTo(int maxId) async => deletedUpTo = maxId;
}

class _FailingStatistics extends Fake implements StatisticsSyncPayloadBuilder {
  @override
  Future<Map<String, Object?>> build() async => throw StateError('stats.db');
}

void main() {
  test('points are synced even when the statistics fail', () async {
    final client = _RecordingClient();
    final outbox = _Outbox();
    final service = SyncService(
      client,
      outbox,
      statistics: _FailingStatistics(),
    );

    expect(await service.syncPendingPoints(), isTrue);

    expect(client.body!['points'], hasLength(2));
    expect(client.body!.containsKey('statistics'), isFalse);
    expect(outbox.deletedUpTo, 9);
  });
}
