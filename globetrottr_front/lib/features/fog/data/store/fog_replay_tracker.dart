import 'dart:async';

import 'package:globetrottr_front/core/async/work_counter.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_path_point.dart';

/// A point logged while the store catches up with the track log.
class FogDeferredPoint {
  FogDeferredPoint(this.sessionId, this.point, this.logId, this.trailId);

  final String sessionId;
  final FogPathPoint point;
  final int? logId;
  final int trailId;

  /// Completes once the point is drawn (or skipped as already drawn).
  final Completer<void> done = Completer<void>();
}

/// Keeps track of the replays and rebuilds of a store. While one runs, new
/// points wait here, so log entries always reach the tiles in log order.
class FogReplayTracker {
  final WorkCounter _catchUps = WorkCounter();
  final List<FogDeferredPoint> _deferred = [];

  bool get isRunning => _catchUps.isBusy;

  /// Holds [point] until the catch-up ends; the future completes when the
  /// point is drawn.
  Future<void> defer(FogDeferredPoint point) {
    _deferred.add(point);
    return point.done.future;
  }

  void begin() => _catchUps.begin();

  /// Ends one catch-up. When none is left it wakes the [whenIdle] callers
  /// and hands back the points that waited; otherwise it returns none.
  List<FogDeferredPoint> end() {
    _catchUps.end();
    if (_catchUps.isBusy) return const [];
    final points = List.of(_deferred);
    _deferred.clear();
    return points;
  }

  /// Completes when no catch-up is running.
  Future<void> whenIdle() => _catchUps.whenIdle();
}
