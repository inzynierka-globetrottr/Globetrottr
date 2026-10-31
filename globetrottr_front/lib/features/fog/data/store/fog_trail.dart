import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_segment_rule.dart';

/// One stretch of the trail in base level world pixels; a lone point has
/// both ends equal.
class FogTrailSegment {
  const FogTrailSegment(this.id, this.ax, this.ay, this.bx, this.by);

  final int id;
  final double ax;
  final double ay;
  final double bx;
  final double by;
}

/// What the player revealed since the last flush, drawn over the tile images
/// with the same values the images will hold. New points reach the images only
/// at a flush, so this is what shows them at once and the same way on every
/// zoom level. Segments leave when the images holding them are ready.
class FogTrail {
  final List<FogTrailSegment> _segments = [];
  int _newestId = 0;
  String? _session;

  /// The newest point, which the player continues from.
  FogPathPoint? anchor;

  List<FogTrailSegment> get segments => List.unmodifiable(_segments);

  bool get isEmpty => _segments.isEmpty;

  /// Adds [point] to the path of [sessionId], by the same rule as the tiles,
  /// and returns the id of the new segment.
  int add(String sessionId, FogPathPoint point, FogSegmentRule rule) {
    final last = anchor;
    final joined =
        last != null && _session == sessionId && rule.connects(last, point);
    final start = joined ? last : point;
    _segments.add(
      FogTrailSegment(++_newestId, start.x, start.y, point.x, point.y),
    );
    anchor = point;
    _session = sessionId;
    return _newestId;
  }

  void forget(int upToId) {
    _segments.removeWhere((segment) => segment.id <= upToId);
  }

  void clear() {
    _segments.clear();
    anchor = null;
  }
}
