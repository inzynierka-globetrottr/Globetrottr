import 'dart:math' as math;

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/fog_store.dart';
import 'package:latlong2/latlong.dart';

/// Questions about the discovered area, answered from the base level tiles.
/// These replace the PostGIS queries quests and statistics use today.
// TODO(fog): not wired yet; quests and statistics still use the backend.
class FogQuery {
  FogQuery(this._store);

  final FogStore _store;

  double get totalDiscoveredKm2 => _store.totalAreaM2 / 1e6;

  /// Coverage of one point, from 0 (fog) to 1 (revealed).
  Future<double> coverageAt(double latitude, double longitude) async {
    final zoom = _store.baseZoom;
    final tile = FogMercator.tileAt(latitude, longitude, zoom);
    final mask = await _store.maskFor(tile);
    if (mask == null) return 0;
    final px = (FogMercator.lngToX(longitude, zoom) - tile.x * FogTileId.size)
        .floor()
        .clamp(0, FogMask.size - 1);
    final py = (FogMercator.latToY(latitude, zoom) - tile.y * FogTileId.size)
        .floor()
        .clamp(0, FogMask.size - 1);
    return mask.at(px, py) / 255.0;
  }

  /// Share of a route (sampled every [stepMeters]) that lies in discovered
  /// area, for quests that ask the player to follow a route.
  Future<double> coveredFractionAlong(
    List<LatLng> route, {
    double stepMeters = 5,
    double threshold = 0.5,
  }) async {
    if (route.isEmpty) return 0;
    const distance = Distance();
    var samples = 0;
    var covered = 0;

    Future<void> sample(LatLng point) async {
      samples++;
      if (await coverageAt(point.latitude, point.longitude) >= threshold) {
        covered++;
      }
    }

    await sample(route.first);
    for (var i = 1; i < route.length; i++) {
      final from = route[i - 1];
      final to = route[i];
      final length = distance(from, to);
      final steps = math.max(1, (length / stepMeters).ceil());
      for (var s = 1; s <= steps; s++) {
        final t = s / steps;
        await sample(
          LatLng(
            from.latitude + (to.latitude - from.latitude) * t,
            from.longitude + (to.longitude - from.longitude) * t,
          ),
        );
      }
    }
    return covered / samples;
  }

  /// Revealed ground area inside a bounding box, in square meters.
  Future<double> coveredAreaM2({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final zoom = _store.baseZoom;
    const size = FogTileId.size;
    final left = FogMercator.lngToX(west, zoom);
    final right = FogMercator.lngToX(east, zoom);
    final top = FogMercator.latToY(north, zoom);
    final bottom = FogMercator.latToY(south, zoom);

    final tileX0 = (left / size).floor();
    final tileX1 = (right / size).floor();
    final tileY0 = (top / size).floor();
    final tileY1 = (bottom / size).floor();

    var area = 0.0;
    for (var ty = tileY0; ty <= tileY1; ty++) {
      for (var tx = tileX0; tx <= tileX1; tx++) {
        final id = FogTileId(zoom, tx, ty);
        final mask = await _store.maskFor(id);
        if (mask == null) continue;
        final x0 = math.max(0, (left - tx * size).ceil());
        final x1 = math.min(size - 1, (right - tx * size).floor() - 1);
        final y0 = math.max(0, (top - ty * size).ceil());
        final y1 = math.min(size - 1, (bottom - ty * size).floor() - 1);
        var sum = 0;
        for (var y = y0; y <= y1; y++) {
          for (var x = x0; x <= x1; x++) {
            sum += mask.at(x, y);
          }
        }
        final latitude = FogMercator.yToLat((ty + 0.5) * size, zoom);
        final pixel = metersPerPixel(
          latitude: latitude,
          zoom: zoom.toDouble(),
        );
        area += sum / 255.0 * pixel * pixel;
      }
    }
    return area;
  }
}
