import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_rasterizer.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_scale.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

/// The last drawn point of a session, in base level world pixels.
class FogLastPoint {
  const FogLastPoint(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

/// Where each recent session ended, so its next point continues the path.
/// Only the latest sessions are kept.
class FogLastPoints {
  static const int _limit = 16;

  final Map<String, FogLastPoint> _points = {};

  FogLastPoint? operator [](String sessionId) => _points[sessionId];

  bool contains(String sessionId) => _points.containsKey(sessionId);

  void remember(String sessionId, FogLastPoint lastPoint) {
    _points.remove(sessionId);
    _points[sessionId] = lastPoint;
    while (_points.length > _limit) {
      _points.remove(_points.keys.first);
    }
  }

  void clear() => _points.clear();
}

class FogPathJob {
  FogPathJob(this.xy, this.radii, {required this.continues});

  final Float64List xy;
  final Float64List radii;

  /// True when the first point was already drawn earlier.
  final bool continues;
}

class FogChunkJob {
  FogChunkJob(this.zoom, this.edgeWidth, this.quantStep, this.paths);

  final int zoom;
  final double edgeWidth;
  final int quantStep;
  final List<FogPathJob> paths;
}

/// Rasterizes [job] into new masks keyed by [FogTileId.key]. It runs in a
/// background isolate, so it only takes and returns plain data.
Map<int, Uint8List> rasterizeChunk(FogChunkJob job) {
  final masks = <FogTileId, FogMask>{};
  final rasterizer = FogRasterizer(
    zoom: job.zoom,
    edgeWidth: job.edgeWidth,
    quantStep: job.quantStep,
  );
  FogMask provide(FogTileId id) => masks.putIfAbsent(id, FogMask.new);

  for (final path in job.paths) {
    final count = path.radii.length;
    if (!path.continues) {
      rasterizer.drawStadium(
        ax: path.xy[0],
        ay: path.xy[1],
        bx: path.xy[0],
        by: path.xy[1],
        radius: path.radii[0],
        maskFor: provide,
      );
    }
    for (var i = 1; i < count; i++) {
      rasterizer.drawStadium(
        ax: path.xy[2 * i - 2],
        ay: path.xy[2 * i - 1],
        bx: path.xy[2 * i],
        by: path.xy[2 * i + 1],
        radius: path.radii[i],
        maskFor: provide,
      );
    }
  }
  return {for (final e in masks.entries) e.key.key: e.value.data};
}

/// Cuts track log entries into chunks and turns them into jobs for
/// [rasterizeChunk].
class FogImportPlanner {
  FogImportPlanner({
    required this.baseZoom,
    required this.radiusMeters,
    required this.segmentRule,
    required this.rasterizer,
  });

  final int baseZoom;
  final double radiusMeters;
  final FogSegmentRule segmentRule;
  final FogRasterizer rasterizer;

  /// End (exclusive) of the chunk starting at [from]: at most [maxPoints]
  /// entries and a path of at most [maxPathPixels] base pixels, but always
  /// at least one entry.
  int chunkEnd(
    List<TrackLogEntry> entries,
    int from,
    int maxPoints,
    double maxPathPixels,
  ) {
    final limit = math.min(entries.length, from + maxPoints);
    var path = 0.0;
    var previous = entries[from];
    var px = FogMercator.lngToX(previous.longitude, baseZoom);
    var py = FogMercator.latToY(previous.latitude, baseZoom);
    for (var i = from + 1; i < limit; i++) {
      final entry = entries[i];
      final x = FogMercator.lngToX(entry.longitude, baseZoom);
      final y = FogMercator.latToY(entry.latitude, baseZoom);
      final radius = metersToPixels(
        meters: radiusMeters,
        latitude: entry.latitude,
        zoom: baseZoom.toDouble(),
      );
      if (entry.sessionId == previous.sessionId &&
          segmentRule.connects(px, py, x, y, radius)) {
        final dx = x - px;
        final dy = y - py;
        path += math.sqrt(dx * dx + dy * dy);
      } else {
        path += FogTileId.size;
      }
      if (path > maxPathPixels) return i;
      previous = entry;
      px = x;
      py = y;
    }
    return limit;
  }

  /// Turns [chunk] into a job and moves [lastPoints] to where each session
  /// ended, so the next chunk continues the same path.
  FogChunkJob buildJob(List<TrackLogEntry> chunk, FogLastPoints lastPoints) {
    final bySession = <String, List<TrackLogEntry>>{};
    for (final entry in chunk) {
      bySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }

    final paths = <FogPathJob>[];
    final newLastPoints = <String, FogLastPoint>{};
    for (final session in bySession.entries) {
      final lastPoint = lastPoints[session.key];
      var xy = <double>[];
      var radii = <double>[];
      var continues = lastPoint != null;
      if (lastPoint != null) {
        xy
          ..add(lastPoint.x)
          ..add(lastPoint.y);
        radii.add(lastPoint.radius);
      }

      // A path that only holds the point it continues from draws nothing.
      void closePath() {
        if (radii.length <= (continues ? 1 : 0)) return;
        paths.add(
          FogPathJob(
            Float64List.fromList(xy),
            Float64List.fromList(radii),
            continues: continues,
          ),
        );
      }

      for (final entry in session.value) {
        final x = FogMercator.lngToX(entry.longitude, baseZoom);
        final y = FogMercator.latToY(entry.latitude, baseZoom);
        final radius = metersToPixels(
          meters: radiusMeters,
          latitude: entry.latitude,
          zoom: baseZoom.toDouble(),
        );
        if (radii.isNotEmpty &&
            !segmentRule.connects(
              xy[xy.length - 2],
              xy[xy.length - 1],
              x,
              y,
              radius,
            )) {
          closePath();
          xy = <double>[];
          radii = <double>[];
          continues = false;
        }
        xy
          ..add(x)
          ..add(y);
        radii.add(radius);
        newLastPoints[session.key] = FogLastPoint(x, y, radius);
      }
      closePath();
    }
    newLastPoints.forEach(lastPoints.remember);
    return FogChunkJob(
      baseZoom,
      rasterizer.edgeWidth,
      rasterizer.quantStep,
      paths,
    );
  }
}
