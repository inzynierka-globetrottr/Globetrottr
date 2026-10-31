import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';

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

/// What the player revealed since the last flush, drawn as vectors over the
/// tiles. New points reach the tiles' images only at a flush, so this is what
/// shows them at once and the same way on every zoom level. Segments leave
/// when the images holding them are ready, so nothing blinks at the hand-over.
class FogTrail {
  final List<FogTrailSegment> _segments = [];
  int _newestId = 0;

  /// The newest point drawn while recording, which the live position
  /// continues from.
  FogPathPoint? anchor;

  List<FogTrailSegment> get segments => List.unmodifiable(_segments);

  int get newestId => _newestId;

  void add(double ax, double ay, double bx, double by) {
    _segments.add(FogTrailSegment(++_newestId, ax, ay, bx, by));
  }

  void forget(int upToId) {
    _segments.removeWhere((segment) => segment.id <= upToId);
  }

  void clear() {
    _segments.clear();
    anchor = null;
  }
}
