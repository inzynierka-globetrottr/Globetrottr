import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_query.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/fog/render/fog_catch_up_indicator.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

import '../../../support/fake_location_service.dart';
import '../../../support/fog_test_helpers.dart';

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

  group('FogStore catch-up progress', () {
    test('is null when idle and reported while replaying', () async {
      final log = InMemoryTrackLogStorage();
      await log.appendAll(walkEast('a', points: 30));
      final store = await FogStore.open(InMemoryFogTileStorage());
      final seen = <double?>[];
      store.catchUpProgress.addListener(
        () => seen.add(store.catchUpProgress.value),
      );

      expect(store.catchUpProgress.value, isNull);
      await store.replayFrom(log, useIsolate: false);

      expect(seen.first, 0);
      expect(seen.whereType<double>().last, 1);
      expect(seen.last, isNull);
      expect(store.catchUpProgress.value, isNull);
      await store.dispose();
    });

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
      expect(store.lastAppliedLogId, await log.lastId());
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
      expect(source.store.catchUpProgress.value, isNotNull);

      log.gate.complete();
      await source.store.whenCaughtUp();

      final middle = offsetMeters(krakowLat, krakowLng, east: 100);
      expect(
        await FogQuery(source.store).coverageAt(middle.lat, middle.lng),
        1,
      );
      expect(source.store.catchUpProgress.value, isNull);
    });
  });

  group('FogCatchUpIndicator', () {
    testWidgets('shows the progress only while catching up', (tester) async {
      final progress = ValueNotifier<double?>(null);
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        MaterialApp(home: FogCatchUpIndicator(progress: progress)),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);

      progress.value = 0.4;
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.4);

      progress.value = null;
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
