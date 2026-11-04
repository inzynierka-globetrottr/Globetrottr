import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/theme/app_map_style.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/map/data/basemap_cache.dart';
import 'package:globetrottr_front/features/map/data/open_free_map_tile_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

class AppTileLayer extends ConsumerWidget {
  const AppTileLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(basemapTileProvider);
    if (tiles == null) return const SizedBox.shrink();
    final cache = ref.watch(basemapCacheProvider);
    final limit = ref.watch(basemapCacheLimitProvider);
    return VectorTileLayer(
      // The layer reads its cache limit only when it is created.
      key: ValueKey(limit),
      theme: AppMapStyle.themeOf(
        context.mapPalette,
        Localizations.localeOf(context).languageCode,
      ),
      tileProviders: TileProviders({
        MapConfig.basemapSource: tiles,
      }),
      // 512 px tiles one zoom level up, which is what the style is made for.
      tileOffset: TileOffset.mapbox,
      cacheFolder: cache.directory,
      fileCacheTtl: MapConfig.basemapCacheTtl,
      fileCacheMaximumSizeInBytes: limit,
    );
  }
}
