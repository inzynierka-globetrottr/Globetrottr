import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_locator.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  test('finds the player where the marker is', () async {
    final container = env.createContainer();
    addTearDown(container.dispose);
    container.read(playerMotionProvider);
    await container.read(locationProvider.notifier).startTracking();
    env.location.emit(50, 19);
    await pumpEventQueue();

    expect(
      await container.read(playerLocatorProvider).locate(),
      const LatLng(50, 19),
    );
  });

  test(
    'while recording it follows the marker, not the newest live fix',
    () async {
      final container = env.createContainer();
      addTearDown(container.dispose);
      container.read(playerMotionProvider);
      final notifier = container.read(locationProvider.notifier);
      await notifier.startTracking();
      env.location.emit(50, 19);
      await pumpEventQueue();
      await notifier.setRecording(true);

      env.location.emit(50.001, 19);
      await pumpEventQueue();

      expect(
        await container.read(playerLocatorProvider).locate(),
        const LatLng(50, 19),
      );
    },
  );

  test('without a position it starts tracking again', () async {
    env.location.startError = Exception('no permission');
    final container = env.createContainer();
    addTearDown(container.dispose);
    await container.read(locationProvider.notifier).startTracking();
    env.location.startError = null;

    expect(await container.read(playerLocatorProvider).locate(), isNull);
    expect(container.read(locationProvider).isTracking, isTrue);
  });

  test('keeps the reason when tracking still cannot start', () async {
    env.location.startError = Exception('no permission');
    final container = env.createContainer();
    addTearDown(container.dispose);

    expect(await container.read(playerLocatorProvider).locate(), isNull);
    expect(container.read(locationProvider).errorMessage, isNotNull);
  });

  test('returns position if startTracking resolves one', () async {
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
    final container = env.createContainer();
    addTearDown(container.dispose);

    expect(
      await container.read(playerLocatorProvider).locate(),
      const LatLng(50.06, 19.94),
    );
  });
}
