import 'dart:math' as math;
import 'dart:ui';

import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@immutable
class FogCamera {
  FogCamera({
    required this.center,
    required this.zoom,
    this.rotation = 0,
    required this.size,
  }) : _scale = math.pow(2, zoom).toDouble(),
       _centerX = FogMercator.lngToX(center.longitude, 0),
       _centerY = FogMercator.latToY(center.latitude, 0),
       _cos = math.cos(rotation * math.pi / 180),
       _sin = math.sin(rotation * math.pi / 180);

  final LatLng center;

  /// On the scale of 256 px tiles: at zoom `z` a tile of level `z` is 256 px
  /// wide. An engine that counts zoom for 512 px tiles (MapLibre) passes its
  /// zoom plus one.
  final double zoom;

  /// In degrees; a positive rotation turns the map clockwise on the screen.
  final double rotation;

  final Size size;

  final double _scale;

  final double _centerX;
  final double _centerY;

  final double _cos;
  final double _sin;

  bool get isUsable =>
      zoom.isFinite &&
      rotation.isFinite &&
      center.latitude.isFinite &&
      center.longitude.isFinite &&
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0;

  Offset toScreen(LatLng position) => _screenOf(
    FogMercator.lngToX(position.longitude, 0),
    FogMercator.latToY(position.latitude, 0),
  );

  Offset worldToScreen(double x, double y, int z) {
    final levelSize = (1 << z).toDouble();
    return _screenOf(x / levelSize, y / levelSize);
  }

  Offset _screenOf(double x0, double y0) {
    final dx = (x0 - _centerX) * _scale;
    final dy = (y0 - _centerY) * _scale;
    return Offset(
      size.width / 2 + _cos * dx - _sin * dy,
      size.height / 2 + _sin * dx + _cos * dy,
    );
  }

  FogTileRange visibleTiles(int z) {
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final reachX = (_cos.abs() * halfWidth + _sin.abs() * halfHeight) / _scale;
    final reachY = (_sin.abs() * halfWidth + _cos.abs() * halfHeight) / _scale;
    final levelSize = (1 << z).toDouble();
    return FogTileRange.covering(
      z: z,
      minX: (_centerX - reachX) * levelSize,
      maxX: (_centerX + reachX) * levelSize,
      minY: (_centerY - reachY) * levelSize,
      maxY: (_centerY + reachY) * levelSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FogCamera &&
      other.center == center &&
      other.zoom == zoom &&
      other.rotation == rotation &&
      other.size == size;

  @override
  int get hashCode => Object.hash(center, zoom, rotation, size);

  @override
  String toString() =>
      'FogCamera($center, zoom $zoom, rotation $rotation, $size)';
}
