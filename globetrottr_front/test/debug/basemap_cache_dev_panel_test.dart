import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/debug/widgets/basemap_cache_dev_panel.dart';
import 'package:globetrottr_front/features/map/data/basemap_cache.dart';

import '../support/fake_basemap_cache.dart';

void main() {
  const mega = 1024 * 1024;

  Future<ProviderContainer> pumpPanel(
    WidgetTester tester,
    FakeBasemapCache cache,
  ) async {
    final container = ProviderContainer(
      overrides: [basemapCacheProvider.overrideWithValue(cache)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: BasemapCacheDevPanel()),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('shows the size, the tiles and the area they cover', (
    tester,
  ) async {
    final cache = FakeBasemapCache(
      current: const BasemapCacheStats(
        vectorTiles: 120,
        vectorBytes: 6 * mega,
        renderedTiles: 80,
        renderedBytes: 24 * mega,
        otherBytes: 0,
        deepestZoomTiles: 40,
        deepestZoomAreaKm2: 98.4,
      ),
    );
    await pumpPanel(tester, cache);

    expect(find.textContaining('30.0 MB'), findsOneWidget);
    expect(find.textContaining('Vector tiles: 120, 6.0 MB'), findsOneWidget);
    expect(find.textContaining('Rendered tiles: 80, 24.0 MB'), findsOneWidget);
    expect(find.textContaining('40 tiles'), findsOneWidget);
    expect(find.textContaining('98.4 km2'), findsOneWidget);
  });

  testWidgets('clearing empties the cache and shows it', (tester) async {
    final cache = FakeBasemapCache(
      current: const BasemapCacheStats(
        vectorTiles: 1,
        vectorBytes: mega,
        renderedTiles: 0,
        renderedBytes: 0,
        otherBytes: 0,
        deepestZoomTiles: 1,
        deepestZoomAreaKm2: 2.5,
      ),
    );
    await pumpPanel(tester, cache);

    await tester.tap(find.text('Clear base map cache'));
    await tester.pump();
    await tester.pump();

    expect(cache.clears, 1);
    expect(find.textContaining('Vector tiles: 0, 0 B'), findsOneWidget);
  });

  testWidgets('a picked limit becomes the cache limit', (tester) async {
    final container = await pumpPanel(tester, FakeBasemapCache());
    expect(
      container.read(basemapCacheLimitProvider),
      MapConfig.basemapCacheMaxBytes,
    );

    await tester.tap(find.text('100 MB'));
    await tester.pump();

    expect(container.read(basemapCacheLimitProvider), 100 * mega);
  });

  testWidgets('leaving the panel stops its refresh', (tester) async {
    await pumpPanel(tester, FakeBasemapCache());

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
  });
}
