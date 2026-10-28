import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';

/// Paints the fog as a dark layer and subtracts the discovered coverage.
///
/// Every visible tile image holds the coverage in its alpha channel. The
/// tiles are added together into one coverage layer ([BlendMode.plus]) which
/// is then removed from the fog ([BlendMode.dstOut]), so partially covered
/// rim pixels give a smooth edge and neighbouring tiles leave no seam. While a tile is not ready, a
/// coarser or finer neighbour level stands in so the fog never flashes.
class BitmapFogPainter extends CustomPainter {
  BitmapFogPainter({
    required this.camera,
    this.source,
    this.liveCenter,
    this.options = defaultOptions,
    this.visionRadiusMeters = FogConfig.visionRadiusMeters,
  }) : super(repaint: source);

  static const FogRenderOptions defaultOptions = FogRenderOptions();
  static const int _maxDrawnTiles = 96;
  static const double _tile = 256;
  static const double _minPixelLineSize = 6;

  final MapCamera camera;
  final FogTileSource? source;

  /// Where the player is while recording; revealed instantly, without
  /// waiting for the next tile update.
  final LatLng? liveCenter;
  final FogRenderOptions options;
  final double visionRadiusMeters;

  @override
  void paint(Canvas canvas, Size size) {
    final timer = Stopwatch()..start();
    final usable = FogTileRange.isUsable(camera);
    final sigma = usable && !options.rawPixels ? _blurSigma() : null;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..imageFilter = sigma == null
            ? null
            : ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.clamp,
              ),
    );
    canvas.drawColor(
      AppColors.fog.withValues(alpha: options.opacity),
      BlendMode.srcOver,
    );
    // Coverage is first summed in its own layer and only then subtracted
    // from the fog. Subtracting tile by tile would multiply the anti-aliased
    // edges of two neighbouring tiles and leave a faint seam on rotated maps.
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.dstOut);
    if (usable) {
      if (source != null) _drawTiles(canvas, source!);
      if (!options.rawPixels) _drawLiveDisc(canvas);
    }
    canvas
      ..restore()
      ..restore();
    if (usable && options.rawPixels) _drawPixelLines(canvas);
    if (usable && options.showGrid) _drawGrid(canvas);
    source?.stats.record(timer.elapsedMicroseconds);
  }

  double? _blurSigma() {
    if (!options.softEdge) return null;
    final groundResolution = metersPerPixel(
      latitude: camera.center.latitude,
      zoom: camera.zoom,
    );
    final sigma = math.min(
      options.maxBlurSigma,
      options.softEdgeMeters / 2 / groundResolution,
    );
    return sigma < 0.4 ? null : sigma;
  }

  /// Thin lines between the fog pixels, drawn only when one pixel covers at
  /// least [_minPixelLineSize] screen pixels, otherwise they would just hide
  /// the data.
  void _drawPixelLines(Canvas canvas) {
    final level = _drawnLevel();
    final pixelSize = math.pow(2, camera.zoom - level).toDouble();
    if (pixelSize < _minPixelLineSize) return;
    final range = FogTileRange.visible(camera, level);
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
    final range = FogTileRange.visible(camera, _drawnLevel());
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
    final range = FogTileRange.visible(camera, level);
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
    final scale = math.sqrt(matrix[0] * matrix[0] + matrix[1] * matrix[1]);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = options.rawPixels
          ? FilterQuality.none
          : (scale > 1.0 ? FilterQuality.high : FilterQuality.medium);
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

  void _drawLiveDisc(Canvas canvas) {
    final center = liveCenter;
    if (center == null) return;
    final radius = metersToPixels(
      meters: visionRadiusMeters,
      latitude: center.latitude,
      zoom: camera.zoom,
    );
    if (radius < 1) return;
    final screen = camera.latLngToScreenPoint(center);
    const rim = 0.75;
    final reach = radius + rim;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        Offset(screen.x, screen.y),
        reach,
        const [Colors.black, Colors.black, Colors.transparent],
        [0, (radius - rim) / reach, 1],
      );
    canvas.drawCircle(Offset(screen.x, screen.y), reach, paint);
  }

  @override
  bool shouldRepaint(covariant BitmapFogPainter oldDelegate) {
    return oldDelegate.source != source ||
        oldDelegate.options != options ||
        oldDelegate.liveCenter != liveCenter ||
        oldDelegate.visionRadiusMeters != visionRadiusMeters ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
