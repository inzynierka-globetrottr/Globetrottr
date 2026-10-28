import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService implements LocationService {
  @override
  void setRecording(bool value) {}

  @override
  void stopTracking() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMapStorage implements MapStorage {
  @override
  Future<List<PendingPoint>> getPendingPoints() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFogService implements FogService {
  @override
  Future<List<List<LatLng>>> getMyFog() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncService implements SyncService {
  _FakeSyncService({required this.succeeds});

  final bool succeeds;

  @override
  Future<bool> syncPendingPoints() async => succeeds;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuestService implements QuestService {
  int fetchCount = 0;

  @override
  Future<List<Quest>> fetchUserQuests() async {
    fetchCount++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeQuestService questService;

  ProviderContainer createContainer({required bool syncSucceeds}) {
    questService = _FakeQuestService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
        mapStorageProvider.overrideWithValue(_FakeMapStorage()),
        fogServiceProvider.overrideWithValue(_FakeFogService()),
        syncServiceProvider.overrideWithValue(
          _FakeSyncService(succeeds: syncSucceeds),
        ),
        questServiceProvider.overrideWithValue(questService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LocationNotifier.setRecording', () {
    test('reloads quests after recording stops and sync succeeds', () async {
      final container = createContainer(syncSucceeds: true);
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);

      expect(questService.fetchCount, 1);
    });

    test('does not reload quests when sync fails', () async {
      final container = createContainer(syncSucceeds: false);
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);

      expect(questService.fetchCount, 0);
    });

    test('does not reload quests when recording starts', () async {
      final container = createContainer(syncSucceeds: true);

      await container.read(locationProvider.notifier).setRecording(true);

      expect(questService.fetchCount, 0);
    });
  });
}
