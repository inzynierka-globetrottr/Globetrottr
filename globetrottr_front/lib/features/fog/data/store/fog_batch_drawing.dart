import 'dart:math' as math;
import 'dart:typed_data';

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_rasterizer.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

/// Where each recent session ended, so its next point continues the path.
/// Only the latest sessions are kept.
class FogLastPoints {
  static const int _limit = 16;

  final Map<String, FogPathPoint> _points = {};

  FogPathPoint? operator [](String sessionId) => _points[sessionId];

  bool contains(String sessionId) => _points.containsKey(sessionId);

  void remember(String sessionId, FogPathPoint lastPoint) {
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
  FogChunkJob(this.rasterizer, this.paths);

  final FogRasterizer rasterizer;
  final List<FogPathJob> paths;
}

/// Rasterizes [job] into new masks keyed by [FogTileId.key]. It runs in a
/// background isolate, so [job] holds only numbers and typed data.
Map<int, Uint8List> rasterizeChunk(FogChunkJob job) {
  final masks = <FogTileId, FogMask>{};
  final rasterizer = job.rasterizer;
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
  FogImportPlanner({required this.segmentRule, required this.rasterizer});

  final FogSegmentRule segmentRule;
  final FogRasterizer rasterizer;

  FogPathPoint _pointOf(TrackLogEntry entry) {
    return FogPathPoint.at(entry.latitude, entry.longitude, rasterizer.zoom);
  }

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
    var session = entries[from].sessionId;
    var previous = _pointOf(entries[from]);
    for (var i = from + 1; i < limit; i++) {
      final entry = entries[i];
      final point = _pointOf(entry);
      if (entry.sessionId == session && segmentRule.connects(previous, point)) {
        final dx = point.x - previous.x;
        final dy = point.y - previous.y;
        path += math.sqrt(dx * dx + dy * dy);
      } else {
        path += FogTileId.size;
      }
      if (path > maxPathPixels) return i;
      session = entry.sessionId;
      previous = point;
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
    final newLastPoints = <String, FogPathPoint>{};
    for (final session in bySession.entries) {
      var previous = lastPoints[session.key];
      var xy = <double>[];
      var radii = <double>[];
      var continues = previous != null;
      if (previous != null) {
        xy
          ..add(previous.x)
          ..add(previous.y);
        radii.add(previous.radius);
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
        final point = _pointOf(entry);
        if (previous != null && !segmentRule.connects(previous, point)) {
          closePath();
          xy = <double>[];
          radii = <double>[];
          continues = false;
        }
        xy
          ..add(point.x)
          ..add(point.y);
        radii.add(point.radius);
        previous = point;
        newLastPoints[session.key] = point;
      }
      closePath();
    }
    newLastPoints.forEach(lastPoints.remember);
    return FogChunkJob(rasterizer, paths);
  }
}
