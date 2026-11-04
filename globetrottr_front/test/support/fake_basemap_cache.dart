import 'dart:async';
import 'dart:io';

import 'package:globetrottr_front/features/map/data/basemap_cache.dart';
import 'package:path/path.dart' as p;

class FakeBasemapCache extends BasemapCache {
  FakeBasemapCache({this.current = const BasemapCacheStats.empty()})
    : super(
        // Outside the project, in case a test lets the real layer write.
        directory: () async =>
            Directory(p.join(Directory.systemTemp.path, 'fake_basemap_cache')),
        deepestZoom: 14,
      );

  BasemapCacheStats current;
  int clears = 0;
  int reads = 0;

  /// Set to make the next reads fail.
  Exception? failure;

  /// Set to keep the next reads waiting until it completes.
  Completer<void>? hold;

  @override
  Future<BasemapCacheStats> stats() async {
    reads++;
    await hold?.future;
    final error = failure;
    if (error != null) throw error;
    return current;
  }

  @override
  Future<void> clear() async {
    clears++;
    current = const BasemapCacheStats.empty();
  }
}
