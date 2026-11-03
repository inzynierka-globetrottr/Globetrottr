import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/heatmap/provider/heatmap_provider.dart';

import '../../../support/fake_location_service.dart';
import '../../../support/fog_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FogTestEnvironment env;

  setUp(() {
    env = FogTestEnvironment();
  });

  test('nothing is counted until the heatmap is opened', () async {
    await env.log.appendAll(walkEast('old'));
    final container = env.createContainer();
    addTearDown(container.dispose);
    await pumpEventQueue();

    expect(container.exists(heatmapProvider), isFalse);
    expect((await env.heatTiles.stats()).tileCount, 0);
  });

  test('counts the existing track log when it is opened', () async {
    final entries = await env.log.appendAll(walkEast('old'));
    final container = env.createContainer();
    addTearDown(container.dispose);

    final source = await container.read(heatmapProvider.future);
    await source.store.whenCaughtUp();

    expect(source.store.diagnostics.lastAppliedLogId, entries.last.id);
    expect((await env.heatTiles.stats()).tileCount, greaterThan(0));
  });

  test('counts points as they are logged once it is open', () async {
    final container = env.createContainer();
    addTearDown(container.dispose);
    final source = await container.read(heatmapProvider.future);
    await source.store.whenCaughtUp();

    final entries = await env.log.appendAll(walkEast('live', points: 12));
    for (final entry in entries) {
      env.location.logged.add(entry);
    }
    await pumpEventQueue();

    expect(source.store.diagnostics.lastAppliedLogId, entries.last.id);
  });

  test('a rebuild keeps what was counted; clear empties it', () async {
    final entries = await env.log.appendAll(walkEast('old'));
    final container = env.createContainer();
    addTearDown(container.dispose);
    final source = await container.read(heatmapProvider.future);
    await source.store.whenCaughtUp();
    final notifier = container.read(heatmapProvider.notifier);

    await notifier.rebuild();
    expect((await env.heatTiles.stats()).tileCount, greaterThan(0));

    await notifier.clear();
    expect((await env.heatTiles.stats()).tileCount, 0);
    expect(source.store.diagnostics.lastAppliedLogId, entries.last.id);
  });
}
