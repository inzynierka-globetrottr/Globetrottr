import 'dart:io';

import 'package:globetrottr_front/features/map/data/basemap_cache.dart';

class FakeBasemapCache extends BasemapCache {
  FakeBasemapCache({this.current = const BasemapCacheStats.empty()})
    : super(
        directory: () async => Directory('fake_basemap_cache'),
        deepestZoom: 14,
      );

  BasemapCacheStats current;
  int clears = 0;

  @override
  Future<BasemapCacheStats> stats() async => current;

  @override
  Future<void> clear() async {
    clears++;
    current = const BasemapCacheStats.empty();
  }
}
