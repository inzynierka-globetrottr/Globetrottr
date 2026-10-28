import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FogPainter extends CustomPainter {
  final List<List<LatLng>> holes;
  final MapCamera camera;
  final int holesRevision;

  FogPainter({
    required this.holes,
    required this.camera,
    required this.holesRevision,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    // TODO(fog): hardcoded colour and opacity, not FogConfig.fogOpacity; this
    // painter goes away with the bitmap friends' fog.
    canvas.drawColor(Colors.black.withValues(alpha: 0.75), BlendMode.srcOver);

    final eraserPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    final visibleBounds = camera.visibleBounds;

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

    canvas.restore();
  }

  static final Expando<LatLngBounds> _holeBounds = Expando();

  bool _intersectsVisible(List<LatLng> points, LatLngBounds visible) {
    final bounds = _holeBounds[points] ??= LatLngBounds.fromPoints(points);
    return bounds.isOverlapping(visible);
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.holesRevision != holesRevision ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
