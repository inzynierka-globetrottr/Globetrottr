import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/fog_track.dart';
import 'package:latlong2/latlong.dart';

/// Drops intermediate points closer than [minSpacing] to the previously kept
/// one. The first and the last point are always preserved, so the shape of the
/// line is unchanged beyond [minSpacing].
List<Offset> thinScreenPoints(List<Offset> points, {double minSpacing = 1.0}) {
  if (points.isEmpty) return const [];

  final kept = <Offset>[points.first];
  final minSpacingSquared = minSpacing * minSpacing;

  for (int i = 1; i < points.length; i++) {
    final isFarEnough =
        (points[i] - kept.last).distanceSquared >= minSpacingSquared;
    if (isFarEnough) {
      kept.add(points[i]);
    } else if (i == points.length - 1 && kept.length > 1) {
      kept[kept.length - 1] = points[i];
    }
  }
  return kept;
}

class FogPainter extends CustomPainter {
  final List<List<LatLng>> holes;
  final List<FogTrack> tracks;
  final MapCamera camera;
  final int holesRevision;
  final double visionRadiusInMeters;

  FogPainter({
    required this.holes,
    required this.camera,
    required this.holesRevision,
    this.tracks = const [],
    this.visionRadiusInMeters = MapConfig.defaultVisionRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawColor(Colors.black.withValues(alpha: 0.75), BlendMode.srcOver);

    final visibleBounds = camera.visibleBounds;

    _eraseHoles(canvas, visibleBounds);
    _eraseTracks(canvas, visibleBounds);

    canvas.restore();
  }

  void _eraseHoles(Canvas canvas, LatLngBounds visibleBounds) {
    final eraserPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    for (final holePoints in holes) {
      if (holePoints.isEmpty) continue;
      if (!_intersectsVisible(holePoints, visibleBounds)) continue;

      final path = ui.Path();

      for (int i = 0; i < holePoints.length; i++) {
        final screenPoint = camera.latLngToScreenPoint(holePoints[i]);
        final offset = Offset(
          screenPoint.x,
          screenPoint.y,
        );

        if (i == 0) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }

      path.close();
      canvas.drawPath(path, eraserPaint);
    }
  }

  // A track is erased as a "stadium" strip: a polyline stroked with a width of
  // twice the vision radius and round caps, so one draw call covers a whole
  // session without gaps between consecutive points.
  void _eraseTracks(Canvas canvas, LatLngBounds visibleBounds) {
    for (final track in tracks) {
      final reach = track.boundsWithMargin(visionRadiusInMeters);
      if (!reach.isOverlapping(visibleBounds)) continue;

      final radiusInPixels = metersToPixels(
        meters: visionRadiusInMeters,
        latitude: track.bounds.center.latitude,
        zoom: camera.zoom,
      );

      final screenPoints = thinScreenPoints([
        for (final point in track.points) _toOffset(point),
      ]);

      if (screenPoints.length == 1) {
        canvas.drawCircle(
          screenPoints.single,
          radiusInPixels,
          Paint()
            ..blendMode = BlendMode.clear
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = ui.Path()
        ..moveTo(screenPoints.first.dx, screenPoints.first.dy);
      for (final point in screenPoints.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = radiusInPixels * 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  Offset _toOffset(LatLng point) {
    final screenPoint = camera.latLngToScreenPoint(point);
    return Offset(screenPoint.x, screenPoint.y);
  }

  static final Expando<LatLngBounds> _holeBounds = Expando();

  bool _intersectsVisible(List<LatLng> points, LatLngBounds visible) {
    final bounds = _holeBounds[points] ??= LatLngBounds.fromPoints(points);
    return bounds.isOverlapping(visible);
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.holesRevision != holesRevision ||
        !identical(oldDelegate.tracks, tracks) ||
        oldDelegate.visionRadiusInMeters != visionRadiusInMeters ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
