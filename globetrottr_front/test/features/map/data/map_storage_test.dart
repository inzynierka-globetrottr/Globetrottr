import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = MapStorage();

  setUp(storage.clearPendingPoints);

  PendingPoint point(int i) => PendingPoint(
    sessionId: 's',
    latitude: 50 + i * 0.0001,
    longitude: 19.9,
    timestamp: 1000 + i,
  );

  test('counts pending points without reading them', () async {
    expect(await storage.getPendingPointsCount(), 0);

    for (var i = 0; i < 3; i++) {
      await storage.insertPendingPoint(point(i));
    }
    expect(await storage.getPendingPointsCount(), 3);

    await storage.clearPendingPoints();
    expect(await storage.getPendingPointsCount(), 0);
  });
}
