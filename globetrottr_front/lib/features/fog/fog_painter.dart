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

  bool _intersectsVisible(List<LatLng> points, LatLngBounds visible) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = (minLat == null || p.latitude < minLat) ? p.latitude : minLat;
      maxLat = (maxLat == null || p.latitude > maxLat) ? p.latitude : maxLat;
      minLng = (minLng == null || p.longitude < minLng) ? p.longitude : minLng;
      maxLng = (maxLng == null || p.longitude > maxLng) ? p.longitude : maxLng;
    }
    return !(maxLat! < visible.south ||
        minLat! > visible.north ||
        maxLng! < visible.west ||
        minLng! > visible.east);
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.holesRevision != holesRevision ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}
