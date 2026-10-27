import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fake_location_service.dart';

void main() {
  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  tearDown(() => env.location.positions.close());

  group('LocationNotifier', () {
    test('starts without tracking or recording', () {
      final container = env.createContainer();
      addTearDown(container.dispose);

      final state = container.read(locationProvider);

      expect(state.isTracking, isFalse);
      expect(state.isRecording, isFalse);
      expect(state.currentPosition, isNull);
    });

    test('follows the position once tracking has started', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);

      await notifier.startTracking();
      env.location.emit(50.0, 19.0);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.isTracking, isTrue);
      expect(state.currentPosition, const LatLng(50.0, 19.0));
    });

    test('keeps the position moving while it is not recording', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();

      env.location.emit(50.0, 19.0);
      env.location.emit(50.1, 19.1);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.currentPosition, const LatLng(50.1, 19.1));
      expect(state.isRecording, isFalse);
    });

    test('ignores positions that are not real coordinates', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      env.location.emit(50.0, 19.0);
      await pumpEventQueue();

      env.location.emit(double.nan, 19.0);
      env.location.emit(50.0, double.infinity);
      env.location.emit(95.0, 19.0);
      await pumpEventQueue();

      expect(
        container.read(locationProvider).currentPosition,
        const LatLng(50.0, 19.0),
      );
    });

    test('reports why tracking could not start', () async {
      env.location.startError = Exception('no permission');
      final container = env.createContainer();
      addTearDown(container.dispose);

      await container.read(locationProvider.notifier).startTracking();

      final state = container.read(locationProvider);
      expect(state.isTracking, isFalse);
      expect(state.errorMessage, contains('no permission'));
    });

    test('turning recording on does not sync', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);

      await container.read(locationProvider.notifier).setRecording(true);

      expect(container.read(locationProvider).isRecording, isTrue);
      expect(env.sync.calls, 0);
    });

    test('turning recording off syncs the pending points once', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);
      await notifier.setRecording(true);

      await notifier.setRecording(false);

      expect(container.read(locationProvider).isRecording, isFalse);
      expect(env.sync.calls, 1);
    });

    test('a failed sync does not break recording', () async {
      env.sync.succeeds = false;
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);

      await notifier.setRecording(true);
      await notifier.setRecording(false);
      await notifier.setRecording(true);

      expect(container.read(locationProvider).isRecording, isTrue);
    });

    test('stops following positions after tracking stops', () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      env.location.emit(50.0, 19.0);
      await pumpEventQueue();

      notifier.stopTracking();
      env.location.emit(51.0, 20.0);
      await pumpEventQueue();

      final state = container.read(locationProvider);
      expect(state.isTracking, isFalse);
      expect(state.currentPosition, const LatLng(50.0, 19.0));
    });
  });
}
