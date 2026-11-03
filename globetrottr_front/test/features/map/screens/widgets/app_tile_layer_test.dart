import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/map/data/basemap_cache.dart';
import 'package:globetrottr_front/features/map/data/open_free_map_tile_provider.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../../support/fake_basemap_cache.dart';

class _SilentTileProvider extends VectorTileProvider {
  @override
  int get maximumZoom => MapConfig.basemapMaxZoom;

  @override
  int get minimumZoom => 0;

  @override
  Future<Uint8List> provide(TileIdentity tile) => Completer<Uint8List>().future;
}

void main() {
  Future<ProviderContainer> pumpLayer(
    WidgetTester tester,
    FakeBasemapCache cache,
  ) async {
    final container = ProviderContainer(
      overrides: [
        basemapTileProvider.overrideWithValue(_SilentTileProvider()),
        basemapCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const FlutterMap(
            options: MapOptions(initialCenter: MapConfig.initialCenter),
            children: [AppTileLayer()],
          ),
        ),
      ),
    );
    return container;
  }

  Future<void> disposeLayer(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('keeps the tiles in the persistent folder for long', (
    tester,
  ) async {
    final cache = FakeBasemapCache();
    await pumpLayer(tester, cache);

    final layer = tester.widget<VectorTileLayer>(find.byType(VectorTileLayer));
    expect(layer.cacheFolder, same(cache.directory));
    expect(layer.fileCacheTtl, MapConfig.basemapCacheTtl);
    expect(layer.fileCacheMaximumSizeInBytes, MapConfig.basemapCacheMaxBytes);

    await disposeLayer(tester);
  });

  testWidgets('a new limit rebuilds the layer with it', (tester) async {
    final container = await pumpLayer(tester, FakeBasemapCache());
    final before = tester.widget<VectorTileLayer>(find.byType(VectorTileLayer));

    container.read(basemapCacheLimitProvider.notifier).set(100 << 20);
    await tester.pump();

    final after = tester.widget<VectorTileLayer>(find.byType(VectorTileLayer));
    expect(after.fileCacheMaximumSizeInBytes, 100 << 20);
    expect(after.key, isNot(before.key));

    await disposeLayer(tester);
  });
}
