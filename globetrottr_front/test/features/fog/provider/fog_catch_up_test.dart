import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

import '../../../support/fake_location_service.dart';
import '../../../support/fog_test_helpers.dart';
import '../../../support/in_memory_fog_tile_storage.dart';
import '../../../support/in_memory_track_log_storage.dart';

/// A track log whose reads wait until [gate] is completed.
class _SlowTrackLog extends InMemoryTrackLogStorage {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<TrackLogEntry>> entriesAfter(
    int afterId, {
    int limit = 5000,
  }) async {
    await gate.future;
    return super.entriesAfter(afterId, limit: limit);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FogStore catch-up', () {
    test('whenCaughtUp completes once the replay is done', () async {
      final log = _SlowTrackLog();
      await log.appendAll(walkEast('a', points: 30));
      final store = await FogStore.open(InMemoryFogTileStorage());
      var done = false;

      unawaited(store.replayFrom(log, useIsolate: false));
      unawaited(store.whenCaughtUp().then((_) => done = true));
      await pumpEventQueue();
      expect(done, isFalse);

      log.gate.complete();
      await store.whenCaughtUp();

      expect(done, isTrue);
      expect(store.diagnostics.lastAppliedLogId, await log.lastId());
      await store.dispose();
    });

    test('whenCaughtUp completes at once when nothing is replaying', () async {
      final store = await FogStore.open(InMemoryFogTileStorage());

      await expectLater(store.whenCaughtUp(), completes);
      await store.dispose();
    });
  });

  group('FogNotifier start', () {
    test('the fog is ready before a long replay finishes', () async {
      final log = _SlowTrackLog();
      await log.appendAll(walkEast('old'));
      final env = FogTestEnvironment(log: log);
      final container = env.createContainer();
      addTearDown(container.dispose);

      final source = await container.read(fogProvider.future);
      var caughtUp = false;
      unawaited(source.store.whenCaughtUp().then((_) => caughtUp = true));
      await pumpEventQueue();
      expect(caughtUp, isFalse);

      log.gate.complete();
      await source.store.whenCaughtUp();

      final middle = offsetMeters(krakowLat, krakowLng, east: 100);
      expect(
        await coverageAt(source.store, middle.lat, middle.lng),
        1,
      );
    });
  });
}
