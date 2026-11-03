import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The folder vector_map_tiles keeps the base map in. It lives in the app
/// support storage, which the system does not wipe to free space as it does
/// the temporary folder, so the map stays where the user has been offline.
final basemapCacheProvider = Provider<BasemapCache>(
  (ref) => BasemapCache(
    directory: _supportFolder,
    deepestZoom: MapConfig.basemapMaxZoom,
  ),
);

Future<Directory> _supportFolder() async {
  final support = await getApplicationSupportDirectory();
  return Directory(p.join(support.path, MapConfig.basemapCacheFolder));
}

class BasemapCacheLimitNotifier extends Notifier<int> {
  @override
  int build() => MapConfig.basemapCacheMaxBytes;

  // The state is the limit itself, so a setter reads best at the call site.
  // ignore: use_setters_to_change_properties
  void set(int bytes) => state = bytes;
}

/// Bytes the base map cache may take before the least recently used tiles
/// are dropped. Only the developer options change it, to try out limits.
final basemapCacheLimitProvider =
    NotifierProvider<BasemapCacheLimitNotifier, int>(
      BasemapCacheLimitNotifier.new,
    );

class BasemapCacheStats {
  const BasemapCacheStats({
    required this.vectorTiles,
    required this.vectorBytes,
    required this.renderedTiles,
    required this.renderedBytes,
    required this.otherBytes,
    required this.deepestZoomTiles,
    required this.deepestZoomAreaKm2,
  });

  const BasemapCacheStats.empty()
    : vectorTiles = 0,
      vectorBytes = 0,
      renderedTiles = 0,
      renderedBytes = 0,
      otherBytes = 0,
      deepestZoomTiles = 0,
      deepestZoomAreaKm2 = 0;

  /// Tiles as downloaded from the server.
  final int vectorTiles;
  final int vectorBytes;

  /// Tiles drawn in the app style and kept as images, so they are not drawn
  /// again; a changed style leaves its old images until they are evicted.
  final int renderedTiles;
  final int renderedBytes;
  final int otherBytes;

  /// Downloaded tiles of the deepest server zoom, which hold every detail of
  /// the map, and the ground they cover.
  final int deepestZoomTiles;
  final double deepestZoomAreaKm2;

  int get totalBytes => vectorBytes + renderedBytes + otherBytes;
}

/// Reads and clears the base map cache. Writing, eviction by size and expiry
/// by age are done by vector_map_tiles itself.
class BasemapCache {
  BasemapCache({required this.directory, required this.deepestZoom});

  final Future<Directory> Function() directory;
  final int deepestZoom;

  static const double _earthRadiusKm = 6371.0088;

  static final _vectorTile = RegExp(r'^(\d+)_(\d+)_(\d+)_.+\.pbf$');

  /// The ground covered by Web Mercator tile row [y] of zoom [z], on a
  /// spherical Earth.
  static double tileAreaKm2(int z, int y) {
    final tiles = math.pow(2, z).toDouble();
    double latitude(int row) =>
        math.atan(_sinh(math.pi * (1 - 2 * row / tiles)));
    final band = math.sin(latitude(y)) - math.sin(latitude(y + 1));
    return _earthRadiusKm * _earthRadiusKm * (2 * math.pi / tiles) * band;
  }

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  Future<BasemapCacheStats> stats() async {
    final path = (await directory()).path;
    final zoom = deepestZoom;
    return Isolate.run(() => _scan(path, zoom));
  }

  Future<void> clear() async {
    final folder = await directory();
    if (!folder.existsSync()) return;
    await for (final entry in folder.list()) {
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        // The tile layer may be replacing the same file right now.
      }
    }
  }

  static BasemapCacheStats _scan(String path, int deepestZoom) {
    final folder = Directory(path);
    if (!folder.existsSync()) return const BasemapCacheStats.empty();
    var vectorTiles = 0;
    var vectorBytes = 0;
    var renderedTiles = 0;
    var renderedBytes = 0;
    var otherBytes = 0;
    var deepestTiles = 0;
    var deepestArea = 0.0;
    for (final entry in folder.listSync()) {
      if (entry is! File) continue;
      final int size;
      try {
        size = entry.lengthSync();
      } on FileSystemException {
        continue;
      }
      final name = p.basename(entry.path);
      final vector = _vectorTile.firstMatch(name);
      if (vector != null) {
        vectorTiles++;
        vectorBytes += size;
        if (int.parse(vector.group(1)!) == deepestZoom) {
          deepestTiles++;
          deepestArea += tileAreaKm2(deepestZoom, int.parse(vector.group(3)!));
        }
      } else if (name.endsWith('.png')) {
        renderedTiles++;
        renderedBytes += size;
      } else {
        otherBytes += size;
      }
    }
    return BasemapCacheStats(
      vectorTiles: vectorTiles,
      vectorBytes: vectorBytes,
      renderedTiles: renderedTiles,
      renderedBytes: renderedBytes,
      otherBytes: otherBytes,
      deepestZoomTiles: deepestTiles,
      deepestZoomAreaKm2: deepestArea,
    );
  }
}
