import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/async/work_counter.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_stats.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_pixels.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';

class FogFallback {
  const FogFallback(this.id, this.image);

  final FogTileId id;
  final ui.Image image;
}

/// Turns the tiles of a [FogStore] into GPU images for the painter and keeps
/// them fresh. It is a [ChangeNotifier]: listeners (the painter) repaint
/// whenever an image becomes ready.
///
/// The painter only ever reads from here synchronously; loading, decoding and
/// refreshing all happen asynchronously off the paint path, and large reads
/// are decoded in an isolate.
class FogTileSource extends ChangeNotifier {
  FogTileSource(this.store, {this.maxImages = 100}) {
    _subscription = store.changes.listen(_onChange);
  }

  static const int _maxRequestedTiles = 400;

  final FogStore store;
  final int maxImages;
  final FogRenderStats stats = FogRenderStats();

  final LinkedHashMap<FogTileId, ui.Image> _images = LinkedHashMap();
  final Set<FogTileId> _stale = {};
  final Set<FogTileId> _building = {};
  final WorkCounter _work = WorkCounter();
  late final StreamSubscription<FogChange> _subscription;

  FogTileRange? _lastRange;
  bool _disposed = false;

  /// Grows when the images are thrown away, so a build started earlier knows
  /// its result is out of date.
  int _generation = 0;

  int get imageCount => _images.length;

  int get pendingBuilds => _work.count;

  /// The pyramid level whose tiles are about 1:1 with the screen at [zoom].
  int levelFor(double zoom) {
    if (!zoom.isFinite) return store.baseZoom;
    return zoom.round().clamp(FogConfig.minZoom, store.baseZoom);
  }

  /// Starts loading what [camera] currently shows (plus a ring around it).
  void ensureVisible(MapCamera camera) {
    if (!camera.isUsableForFog) return;
    ensureRange(camera.visibleTiles(levelFor(camera.zoom)));
  }

  @visibleForTesting
  void ensureRange(FogTileRange range) {
    if (_disposed || range == _lastRange) return;
    _lastRange = range;
    final ring = range.expand(1);
    final target = ring.cellCount <= _maxRequestedTiles
        ? ring
        : (range.cellCount <= _maxRequestedTiles ? range : null);
    if (target == null) return;
    unawaited(_load(target));
  }

  Future<void> _load(FogTileRange target) async {
    _work.begin();
    try {
      await store.prepare(target);
      if (_disposed) return;
      for (final id in target.ids) {
        if (store.peek(id) != null) _request(id);
      }
    } on Object catch (error) {
      debugPrint('Loading fog tiles failed: $error');
      _lastRange = null;
    } finally {
      _work.end();
    }
  }

  /// A ready image of the tile, or null.
  ui.Image? imageFor(FogTileId id) {
    final image = _images[id];
    if (image == null) return null;
    _images.remove(id);
    _images[id] = image;
    return image;
  }

  /// True when the tile is known to have no discovered area at all.
  bool isAbsent(FogTileId id) => store.isKnownAbsent(id);

  /// The image of the closest coarser tile that is already available.
  FogFallback? fallbackFor(FogTileId id) {
    for (var z = id.z - 1; z >= FogConfig.minZoom; z--) {
      final ancestor = id.ancestorAt(z);
      final image = _images[ancestor];
      if (image != null) return FogFallback(ancestor, image);
    }
    return null;
  }

  /// Images of the four finer tiles inside [id] that are already available.
  List<FogFallback> childrenFor(FogTileId id) {
    if (id.z >= store.baseZoom) return const [];
    final result = <FogFallback>[];
    for (var dy = 0; dy < 2; dy++) {
      for (var dx = 0; dx < 2; dx++) {
        final child = FogTileId(id.z + 1, id.x * 2 + dx, id.y * 2 + dy);
        final image = _images[child];
        if (image != null) result.add(FogFallback(child, image));
      }
    }
    return result;
  }

  /// Completes when no tile is being loaded or decoded.
  Future<void> whenIdle() => _work.whenIdle();

  void _onChange(FogChange change) {
    if (_disposed) return;
    if (change.all) {
      _clearImages();
      final range = _lastRange;
      _lastRange = null;
      if (range != null) ensureRange(range);
      notifyListeners();
      return;
    }
    if (change.onTrail) {
      notifyListeners();
      return;
    }

    final written = change.trailWrittenUpTo;
    final wanted = _lastRange?.expand(1);
    final refresh = <FogTileId>{...change.tiles};
    if (written != null) {
      for (final id in change.tiles) {
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            refresh.add(FogTileId(id.z, id.x + dx, id.y + dy));
          }
        }
      }
    }
    for (final id in refresh) {
      final hasImage = _images.containsKey(id);
      final visible = wanted?.contains(id) ?? false;
      if (hasImage || (visible && change.tiles.contains(id))) {
        _stale.add(id);
        _request(id);
      }
    }

    if (written != null) unawaited(_releaseTrail(written));
  }

  /// Drops the trail once the new images hold what it shows. Until then both
  /// are drawn, which changes nothing: they are merged by their maximum.
  Future<void> _releaseTrail(int upToId) async {
    await whenIdle();
    if (_disposed) return;
    store.trail.forget(upToId);
    notifyListeners();
  }

  void _request(FogTileId id) {
    if (_disposed || _building.contains(id)) return;
    if (_images.containsKey(id) && !_stale.contains(id)) return;
    final mask = store.peek(id);
    if (mask == null) return;

    _stale.remove(id);
    _building.add(id);
    _work.begin();
    final pixels = FogTilePixels.build(
      mask,
      neighbor: (dx, dy) => store.peek(FogTileId(id.z, id.x + dx, id.y + dy)),
    );
    final generation = _generation;
    unawaited(
      _decode(pixels).then((image) => _finishBuild(id, image, generation)),
    );
  }

  void _finishBuild(FogTileId id, ui.Image image, int generation) {
    _building.remove(id);
    if (generation == _generation) {
      _images.remove(id)?.dispose();
      _images[id] = image;
      _evictImages();
      notifyListeners();
    } else {
      image.dispose();
    }
    if (_stale.contains(id)) _request(id);
    _work.end();
  }

  void _evictImages() {
    if (_images.length <= maxImages) return;
    final wanted = _lastRange?.expand(1);
    for (final id in _images.keys.toList()) {
      if (_images.length <= maxImages) break;
      if (wanted != null && wanted.contains(id)) continue;
      _images.remove(id)?.dispose();
      _stale.remove(id);
    }
  }

  void _clearImages() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _stale.clear();
    _generation++;
  }

  Future<ui.Image> _decode(Uint8List pixels) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      FogTilePixels.side,
      FogTilePixels.side,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    _clearImages();
    _work.release();
    super.dispose();
  }
}
