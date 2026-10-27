import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/data/fog_query.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

import '../../../support/fake_location_service.dart';
import '../../../support/fog_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  group('FogNotifier', () {
    test('draws the existing track log when it starts', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);

      final source = await container.read(fogProvider.future);

      final middle = offsetMeters(krakowLat, krakowLng, east: 100);
      expect(
        await FogQuery(source.store).coverageAt(middle.lat, middle.lng),
        1,
      );
    });

    test('draws points as they are logged', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);

      final entries = await env.log.appendAll(walkEast('live', points: 12));
      for (final entry in entries) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      await source.store.flush();

      const expected = 2 * 30 * 110 + math.pi * 30 * 30;
      expect(source.store.totalAreaM2, closeTo(expected, expected * 0.04));
      expect(source.store.lastAppliedLogId, entries.last.id);
    });

    test('flushes the fog when recording stops', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      final notifier = container.read(locationProvider.notifier);
      await notifier.setRecording(true);
      final entries = await env.log.appendAll(walkEast('live', points: 5));
      for (final entry in entries) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      expect(source.store.revision, 0);

      await notifier.setRecording(false);
      await pumpEventQueue();

      expect(source.store.revision, 1);
    });

    test('recovers after a restart without duplicating anything', () async {
      final first = env.createContainer();
      final source = await first.read(fogProvider.future);
      final entries = await env.log.appendAll(walkEast('a', points: 30));
      for (final entry in entries.take(10)) {
        env.location.logged.add(entry);
      }
      await pumpEventQueue();
      await source.store.flush();
      final after10 = source.store.totalAreaM2;
      expect(after10, greaterThan(0));
      first.dispose();

      final second = env.createContainer();
      addTearDown(second.dispose);
      final restarted = await second.read(fogProvider.future);

      const expected = 2 * 30 * 290 + math.pi * 30 * 30;
      expect(restarted.store.totalAreaM2, closeTo(expected, expected * 0.04));
      expect(restarted.store.lastAppliedLogId, entries.last.id);
    });

    test('imports entries and keeps them in the fog', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      await container.read(fogProvider.future);
      final notifier = container.read(fogProvider.notifier);

      await notifier.importEntries(
        walkEast('dev', points: 40),
        useIsolate: false,
      );

      final source = container.read(fogProvider).requireValue;
      expect(source.store.totalAreaM2, greaterThan(0));
      expect(await env.log.count(), 40);
    });

    test('clearing the fog keeps the track log', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      expect(source.store.totalAreaM2, greaterThan(0));

      await container.read(fogProvider.notifier).clearFog();

      expect(source.store.totalAreaM2, 0);
      expect(await env.log.count(), 20);
    });

    test('a cleared fog stays cleared after a restart', () async {
      await env.log.appendAll(walkEast('old'));
      final first = env.createContainer();
      await first.read(fogProvider.future);
      await first.read(fogProvider.notifier).clearFog();
      first.dispose();

      final second = env.createContainer();
      addTearDown(second.dispose);
      final restarted = await second.read(fogProvider.future);

      expect(restarted.store.totalAreaM2, 0);
      expect(await env.log.count(), 20);
    });

    test('rebuilding redraws the fog from the track log', () async {
      await env.log.appendAll(walkEast('old'));
      final container = env.createContainer();
      addTearDown(container.dispose);
      final source = await container.read(fogProvider.future);
      final area = source.store.totalAreaM2;
      await container.read(fogProvider.notifier).clearFog();

      await container.read(fogProvider.notifier).rebuild(useIsolate: false);

      expect(source.store.totalAreaM2, closeTo(area, 1e-6));
    });
  });
}
