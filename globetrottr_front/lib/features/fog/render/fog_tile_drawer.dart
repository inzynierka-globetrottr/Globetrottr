import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

/// Draws the tile images of a [TileLayerSource] where [camera] shows them, as
/// brightness added together ([BlendMode.plus]) so neighbouring tiles leave
/// no seam. While a tile is not ready, a coarser or finer neighbour level
/// stands in so the layer never flashes. Painters turn the brightness into
/// fog or colour afterwards.
class FogTileDrawer {
  const FogTileDrawer(this.camera);

  /// Most tiles drawn in one frame; a view needing more is not drawn.
  static const int maxDrawnTiles = 96;
  static const double tile = FogTileId.size + 0.0;

  final MapCamera camera;

  void drawTiles(
    Canvas canvas,
    TileLayerSource source, {
    FilterQuality quality = FilterQuality.low,
  }) {
    final level = source.levelFor(camera.zoom);
    final range = camera.visibleTiles(level);
    if (range.cellCount > maxDrawnTiles) return;
    for (final id in range.ids) {
      final image = source.imageFor(id);
      if (image != null) {
        _drawImage(
          canvas,
          id,
          image,
          const Rect.fromLTWH(1, 1, tile, tile),
          quality,
        );
      } else if (!source.isAbsent(id)) {
        _drawFallback(canvas, source, id, quality);
      }
    }
  }

  void _drawFallback(
    Canvas canvas,
    TileLayerSource source,
    FogTileId id,
    FilterQuality quality,
  ) {
    final ancestor = source.fallbackFor(id);
    if (ancestor != null) {
      final span = 1 << (id.z - ancestor.id.z);
      final side = tile / span;
      final src = Rect.fromLTWH(
        1 + (id.x % span) * side,
        1 + (id.y % span) * side,
        side,
        side,
      );
      _drawImage(canvas, id, ancestor.image, src, quality);
      return;
    }
    for (final child in source.childrenFor(id)) {
      const half = tile / 2;
      final dest = Rect.fromLTWH(
        (child.id.x - id.x * 2) * half,
        (child.id.y - id.y * 2) * half,
        half,
        half,
      );
      _drawImage(
        canvas,
        id,
        child.image,
        const Rect.fromLTWH(1, 1, tile, tile),
        quality,
        dest: dest,
      );
    }
  }

  void _drawImage(
    Canvas canvas,
    FogTileId id,
    ui.Image image,
    Rect src,
    FilterQuality quality, {
    Rect dest = const Rect.fromLTWH(0, 0, tile, tile),
  }) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = quality;
    canvas
      ..save()
      ..transform(tileMatrix(id))
      ..drawImageRect(image, src, dest, paint)
      ..restore();
  }

  /// Maps tile pixels to the screen using the projected corners, so rotation
  /// and any camera state are handled by the map itself.
  Float64List tileMatrix(FogTileId id) {
    final origin = screen(id.x * tile, id.y * tile, id.z);
    final right = screen((id.x + 1) * tile, id.y * tile, id.z);
    final down = screen(id.x * tile, (id.y + 1) * tile, id.z);
    return Float64List.fromList([
      (right.dx - origin.dx) / tile,
      (right.dy - origin.dy) / tile,
      0,
      0,
      (down.dx - origin.dx) / tile,
      (down.dy - origin.dy) / tile,
      0,
      0,
      0,
      0,
      1,
      0,
      origin.dx,
      origin.dy,
      0,
      1,
    ]);
  }

  /// The screen position of world pixel ([worldX], [worldY]) of level [z].
  Offset screen(double worldX, double worldY, int z) {
    final point = camera.latLngToScreenPoint(
      LatLng(FogMercator.yToLat(worldY, z), FogMercator.xToLng(worldX, z)),
    );
    return Offset(point.x, point.y);
  }
}
