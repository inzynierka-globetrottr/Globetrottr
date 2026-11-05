import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';

extension FlutterMapFogCamera on MapCamera {
  FogCamera toFogCamera() {
    final size = Size(nonRotatedSize.x, nonRotatedSize.y);
    final world = project(center);
    final finite =
        world.x.isFinite &&
        world.y.isFinite &&
        rotation.isFinite &&
        size.isFinite;
    if (!finite) {
      return FogCamera(
        center: center,
        zoom: zoom,
        rotation: rotation,
        size: size,
      );
    }

    // flutter_map rounds the top left corner of the view to whole pixels
    // before it projects anything, so its map sits up to half a pixel away
    // from the exact camera. Moving the center by that fraction, turned back
    // by the rotation, puts the fog on the very same pixels.
    final originX = world.x - size.width / 2;
    final originY = world.y - size.height / 2;
    final dx = originX - originX.round();
    final dy = originY - originY.round();
    final cos = math.cos(rotationRad);
    final sin = math.sin(rotationRad);
    final shifted = math.Point<double>(
      world.x - (cos * dx + sin * dy),
      world.y - (cos * dy - sin * dx),
    );

    return FogCamera(
      center: unproject(shifted),
      zoom: zoom,
      rotation: rotation,
      size: size,
    );
  }
}
