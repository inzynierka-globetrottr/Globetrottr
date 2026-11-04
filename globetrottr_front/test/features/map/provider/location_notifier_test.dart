import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fake_location_service.dart';

void main() {
  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  tearDown(() => env.location.positions.close());

  ProviderContainer createContainer() {
    final container = env.createContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('LocationNotifier', () {
    test('starts without tracking or recording', () {
      final container = createContainer();

      final state = container.read(locationProvider);

      expect(state.isTracking, isFalse);
      expect(state.isRecording, isFalse);
      expect(state.currentPosition, isNull);
    });

    test('follows the position once tracking has started', () async {
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);

      await notifier.startTracking();
      env.location.emit(50.0, 19.0);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.isTracking, isTrue);
      expect(state.currentPosition, const LatLng(50.0, 19.0));
    });

    test(
      'seeds currentPosition from last known position when available',
      () async {
        env.location.lastKnownPosition = Position(
          latitude: 50.06,
          longitude: 19.94,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        final container = createContainer();
        final notifier = container.read(locationProvider.notifier);

        await notifier.startTracking();

        final state = container.read(locationProvider);
        expect(state.isTracking, isTrue);
        expect(state.currentPosition, const LatLng(50.06, 19.94));
      },
    );

    test('keeps the position moving while it is not recording', () async {
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();

      env.location.emit(50.0, 19.0);
      env.location.emit(50.1, 19.1);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.currentPosition, const LatLng(50.1, 19.1));
      expect(state.isRecording, isFalse);
    });

    test('starting twice follows every position once', () async {
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      await notifier.startTracking();
      var updates = 0;
      container.listen(locationProvider, (_, _) => updates++);

      env.location.emit(50.0, 19.0);
      await pumpEventQueue();

      expect(updates, 1);
    });

    test('reports why tracking could not start', () async {
      env.location.startError = Exception('no permission');
      final container = createContainer();

      await container.read(locationProvider.notifier).startTracking();

      final state = container.read(locationProvider);
      expect(state.isTracking, isFalse);
      expect(state.errorMessage, contains('no permission'));
    });

    test('turning recording on does not sync', () async {
      final container = createContainer();

      await container.read(locationProvider.notifier).setRecording(true);

      expect(container.read(locationProvider).isRecording, isTrue);
      expect(env.sync.calls, 0);
    });

    test('turning recording off syncs the pending points once', () async {
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);
      await notifier.setRecording(true);

      await notifier.setRecording(false);

      expect(container.read(locationProvider).isRecording, isFalse);
      expect(env.sync.calls, 1);
    });

    test('a walk does not start while tracking cannot start', () async {
      env.location.startError = Exception('no permission');
      final container = env.createContainer();
      addTearDown(container.dispose);

      final started = await container
          .read(locationProvider.notifier)
          .startRecording();

      expect(started, isFalse);
      expect(container.read(locationProvider).isRecording, isFalse);
    });

    test('starting a walk retries tracking that failed before', () async {
      env.location.startError = Exception('no permission');
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      env.location.startError = null;

      final started = await notifier.startRecording();

      final state = container.read(locationProvider);
      expect(started, isTrue);
      expect(state.isTracking, isTrue);
      expect(state.isRecording, isTrue);
    });

    test('a failed sync does not break recording', () async {
      env.sync.succeeds = false;
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);
      await notifier.setRecording(true);

      expect(container.read(locationProvider).isRecording, isTrue);
    });

    test('reloads quests after recording stops and sync succeeds', () async {
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);

      expect(env.quests.fetchCount, 1);
    });

    test('does not reload quests when sync fails', () async {
      env.sync.succeeds = false;
      final container = createContainer();
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);

      expect(env.quests.fetchCount, 0);
    });

    test('does not reload quests when recording starts', () async {
      final container = createContainer();

      await container.read(locationProvider.notifier).setRecording(true);

      expect(env.quests.fetchCount, 0);
    });
  });
}
