import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  test('follows the live position while not recording', () async {
    final container = env.createContainer();
    addTearDown(container.dispose);
    final motion = container.read(playerMotionProvider);
    await container.read(locationProvider.notifier).startTracking();

    env.location.emit(50, 19);
    await pumpEventQueue();

    expect(motion.value, const LatLng(50, 19));
  });

  test('takes a position known before it was created', () async {
    final container = env.createContainer();
    addTearDown(container.dispose);
    await container.read(locationProvider.notifier).startTracking();
    env.location.emit(50, 19);
    await pumpEventQueue();

    final motion = container.read(playerMotionProvider);

    expect(motion.value, const LatLng(50, 19));
  });

  test('while recording it follows only what is stored', () async {
    final container = env.createContainer();
    addTearDown(container.dispose);
    final motion = container.read(playerMotionProvider);
    final notifier = container.read(locationProvider.notifier);
    await notifier.startTracking();
    env.location.emit(50, 19);
    await pumpEventQueue();
    await notifier.setRecording(true);

    env.location.emit(50.001, 19);
    await pumpEventQueue();
    expect(motion.value, const LatLng(50, 19));

    env.location.logged.add(
      const TrackLogEntry(
        id: 1,
        sessionId: 'a',
        timestampMs: 1,
        latitude: 50.001,
        longitude: 19,
      ),
    );
    await pumpEventQueue();

    expect(motion.value, const LatLng(50.001, 19));
  });
}
