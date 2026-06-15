import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FogPainter extends CustomPainter {
  final List<List<LatLng>> holes;
  final MapCamera camera;

  FogPainter({required this.holes, required this.camera});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    canvas.drawColor(Colors.black.withValues(alpha: 0.75), BlendMode.srcOver);

    final eraserPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    for (final holePoints in holes) {
      if (holePoints.isEmpty) continue;

      final path = ui.Path();

      for (int i = 0; i < holePoints.length; i++) {
        final screenPoint = camera.latLngToScreenPoint(holePoints[i]);
        final offset = Offset(
          screenPoint.x.toDouble(),
          screenPoint.y.toDouble(),
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

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    // TODO: consider whether these comparisons are correct (reference vs value)
    return oldDelegate.holes != holes || oldDelegate.camera != camera;
  }
}
