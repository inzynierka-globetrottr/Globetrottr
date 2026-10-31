import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_pyramid.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/render/fog_live_shapes.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

/// Paints the fog from one layer of coverage, drawn as brightness on black.
///
/// Tile images go in first; neighbouring tiles are added ([BlendMode.plus]) so
/// they leave no seam. What the images do not show yet is drawn over them as
/// the very same values, so nothing changes on the screen when an image takes
/// over. A colour filter then turns the layer into fog: it steepens the soft
/// edge stored in the tiles to the width wanted on the screen, which keeps the
/// edge smooth at any zoom. While a tile is not ready, a coarser or finer
/// neighbour level stands in so the fog never flashes.
class BitmapFogPainter extends CustomPainter {
  BitmapFogPainter({
    required this.camera,
    this.source,
    this.head,
    this.options = defaultOptions,
  }) : super(repaint: Listenable.merge([source, head]));

  static const FogRenderOptions defaultOptions = FogRenderOptions();
  static const int _maxDrawnTiles = 96;
  static const double _tile = FogTileId.size + 0.0;
  static const double _minPixelLineSize = 6;

  /// Narrowest edge on the screen; a sharper one would show its pixels.
  static const double _minEdgePixels = 1.5;

  final MapCamera camera;
  final FogTileSource? source;

  /// The player while recording. Read at paint time, so the fog is revealed
  /// up to where the marker is drawn in the same frame.
  final ValueListenable<LatLng?>? head;
  final FogRenderOptions options;

  @override
  void paint(Canvas canvas, Size size) {
    final timer = Stopwatch()..start();
    final usable = camera.isUsableForFog;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawColor(
      AppColors.fog.withValues(alpha: FogConfig.fogOpacity),
      BlendMode.srcOver,
    );
    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..colorFilter = _coverageFilter(usable ? _edgeContrast() : 1)
        ..blendMode = BlendMode.dstOut,
    );
    canvas.drawColor(Colors.black, BlendMode.src);
    if (usable && source != null) {
      _drawTiles(canvas, source!);
      if (!options.rawPixels) _drawLive(canvas, source!, size);
    }
    canvas
      ..restore()
      ..restore();
    if (usable && options.rawPixels) _drawPixelLines(canvas);
    if (usable && options.showGrid) _drawGrid(canvas);
    source?.stats.record(timer.elapsedMicroseconds);
  }

  /// Turns brightness into the alpha that is removed from the fog. `contrast`
  /// steepens the edge around its middle, which stays at the vision radius.
  static ColorFilter _coverageFilter(double contrast) {
    return ColorFilter.matrix(<double>[
      0, 0, 0, 0, 0, //
      0, 0, 0, 0, 0, //
      0, 0, 0, 0, 0, //
      contrast, 0, 0, 0, (1 - contrast) * 127.5,
    ]);
  }

  double _edgeContrast() {
    if (options.rawPixels) return 1;
    final wanted = options.softEdge
        ? options.softEdgeMeters /
              metersPerPixel(
                latitude: camera.center.latitude,
                zoom: camera.zoom,
              )
        : 0.0;
    return math.max(1, _rimOnScreen / math.max(wanted, _minEdgePixels));
  }

  /// Width on the screen of the soft edge stored in the tiles.
  double get _rimOnScreen {
    final base = source?.store.baseZoom ?? FogConfig.baseZoom;
    return FogConfig.edgeWidthPixels * math.pow(2, camera.zoom - base);
  }

  /// Thin lines between the fog pixels, drawn only when one pixel covers at
  /// least [_minPixelLineSize] screen pixels, otherwise they would just hide
  /// the data.
  void _drawPixelLines(Canvas canvas) {
    final level = _drawnLevel();
    final pixelSize = math.pow(2, camera.zoom - level).toDouble();
    if (pixelSize < _minPixelLineSize) return;
    final range = camera.visibleTiles(level);
    if (range.cellCount > _maxDrawnTiles) return;

    final lines = ui.Path();
    for (var i = 0; i <= _tile; i++) {
      lines
        ..moveTo(i.toDouble(), 0)
        ..lineTo(i.toDouble(), _tile)
        ..moveTo(0, i.toDouble())
        ..lineTo(_tile, i.toDouble());
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / pixelSize
      ..color = AppColors.devPixelLines;
    for (final id in range.ids) {
      canvas
        ..save()
        ..transform(_tileMatrix(id))
        ..drawPath(lines, paint)
        ..restore();
    }
  }

  int _drawnLevel() =>
      source?.levelFor(camera.zoom) ??
      camera.zoom.round().clamp(FogConfig.minZoom, FogConfig.baseZoom);

  /// Outlines every tile of the level being drawn and prints its `z/x/y`.
  /// The colour tells the state: green has fog data, grey has none, orange
  /// is still loading.
  void _drawGrid(Canvas canvas) {
    final source = this.source;
    final range = camera.visibleTiles(_drawnLevel());
    if (range.cellCount > _maxDrawnTiles) return;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final id in range.ids) {
      final color = switch (source) {
        null => AppColors.devGridUnknown,
        final s when s.imageFor(id) != null => AppColors.devGridReady,
        final s when s.isAbsent(id) => AppColors.devGridEmpty,
        _ => AppColors.devGridLoading,
      };
      line.color = color;
      final origin = _screen(id.x * _tile, id.y * _tile, id.z);
      final right = _screen((id.x + 1) * _tile, id.y * _tile, id.z);
      final corner = _screen((id.x + 1) * _tile, (id.y + 1) * _tile, id.z);
      final down = _screen(id.x * _tile, (id.y + 1) * _tile, id.z);
      canvas.drawPath(
        ui.Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(down.dx, down.dy)
          ..close(),
        line,
      );
      _drawGridLabel(canvas, '${id.z}/${id.x}/${id.y}', origin, color);
    }
  }

  void _drawGridLabel(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          backgroundColor: AppColors.devGridLabelBackground,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at + const Offset(6, 6));
    painter.dispose();
  }

  void _drawTiles(Canvas canvas, FogTileSource source) {
    final level = source.levelFor(camera.zoom);
    final range = camera.visibleTiles(level);
    if (range.cellCount > _maxDrawnTiles) return;
    for (final id in range.ids) {
      final image = source.imageFor(id);
      if (image != null) {
        _drawImage(canvas, id, image, const Rect.fromLTWH(1, 1, _tile, _tile));
      } else if (!source.isAbsent(id)) {
        _drawFallback(canvas, source, id);
      }
    }
  }

  void _drawFallback(Canvas canvas, FogTileSource source, FogTileId id) {
    final ancestor = source.fallbackFor(id);
    if (ancestor != null) {
      final span = 1 << (id.z - ancestor.id.z);
      final side = _tile / span;
      final src = Rect.fromLTWH(
        1 + (id.x % span) * side,
        1 + (id.y % span) * side,
        side,
        side,
      );
      _drawImage(canvas, id, ancestor.image, src);
      return;
    }
    for (final child in source.childrenFor(id)) {
      const half = _tile / 2;
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
        const Rect.fromLTWH(1, 1, _tile, _tile),
        dest: dest,
      );
    }
  }

  void _drawImage(
    Canvas canvas,
    FogTileId id,
    ui.Image image,
    Rect src, {
    Rect dest = const Rect.fromLTWH(0, 0, _tile, _tile),
  }) {
    final matrix = _tileMatrix(id);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = options.rawPixels
          ? FilterQuality.none
          : FilterQuality.low;
    canvas
      ..save()
      ..transform(matrix)
      ..drawImageRect(image, src, dest, paint)
      ..restore();
  }

  /// Maps tile pixels to the screen using the projected corners, so rotation
  /// and any camera state are handled by the map itself.
  Float64List _tileMatrix(FogTileId id) {
    final origin = _screen(id.x * _tile, id.y * _tile, id.z);
    final right = _screen((id.x + 1) * _tile, id.y * _tile, id.z);
    final down = _screen(id.x * _tile, (id.y + 1) * _tile, id.z);
    return Float64List.fromList([
      (right.dx - origin.dx) / _tile,
      (right.dy - origin.dy) / _tile,
      0,
      0,
      (down.dx - origin.dx) / _tile,
      (down.dy - origin.dy) / _tile,
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

  Offset _screen(double worldX, double worldY, int z) {
    final point = camera.latLngToScreenPoint(
      LatLng(FogMercator.yToLat(worldY, z), FogMercator.xToLng(worldX, z)),
    );
    return Offset(point.x, point.y);
  }

  /// Draws what the tile images do not show yet: the points since the last
  /// flush, and the stretch from the newest one to the player.
  void _drawLive(Canvas canvas, FogTileSource source, Size size) {
    final store = source.store;
    final z = store.baseZoom;
    final shapes = FogLiveShapes(
      canvas,
      Offset.zero & size,
      radius: metersToPixels(
        meters: FogConfig.visionRadiusMeters,
        latitude: camera.center.latitude,
        zoom: camera.zoom,
      ),
      rim: math.max(_rimOnScreen, _minEdgePixels),
      value: _liveValue(source),
    );
    for (final segment in store.trail.segments) {
      shapes.add(
        _screen(segment.ax, segment.ay, z),
        _screen(segment.bx, segment.by, z),
      );
    }

    final position = head?.value;
    if (position == null) return;
    final point = camera.latLngToScreenPoint(position);
    final end = Offset(point.x, point.y);
    final anchor = store.trail.anchor;
    final joined =
        anchor != null &&
        store.joinsTrail(position.latitude, position.longitude);
    shapes.add(joined ? _screen(anchor.x, anchor.y, z) : end, end);
  }

  /// Matches the strength of a thin route in the coarse tiles, so nothing
  /// changes when they take over.
  double _liveValue(FogTileSource source) {
    final level = source.levelFor(camera.zoom);
    final levelWidth =
        2 *
        metersToPixels(
          meters: FogConfig.visionRadiusMeters,
          latitude: camera.center.latitude,
          zoom: level.toDouble(),
        );
    const floor = FogPyramid.defaultOverviewFloor / 255;
    return (floor + (levelWidth - 1) * (1 - floor)).clamp(floor, 1.0);
  }

  @override
  bool shouldRepaint(covariant BitmapFogPainter oldDelegate) {
    return oldDelegate.source != source ||
        oldDelegate.options != options ||
        oldDelegate.head != head ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
