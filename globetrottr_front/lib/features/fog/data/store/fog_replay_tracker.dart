import 'dart:async';

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
  int _running = 0;
  final List<FogDeferredPoint> _deferred = [];
  final List<Completer<void>> _idleWaiters = [];

  bool get isRunning => _running > 0;

  /// Holds [point] until the catch-up ends; the future completes when the
  /// point is drawn.
  Future<void> defer(FogDeferredPoint point) {
    _deferred.add(point);
    return point.done.future;
  }

  void begin() {
    _running++;
  }

  /// Ends one catch-up. When none is left it wakes the [whenIdle] callers
  /// and hands back the points that waited; otherwise it returns none.
  List<FogDeferredPoint> end() {
    _running--;
    if (_running > 0) return const [];
    final waiters = List.of(_idleWaiters);
    _idleWaiters.clear();
    for (final waiter in waiters) {
      waiter.complete();
    }
    final points = List.of(_deferred);
    _deferred.clear();
    return points;
  }

  /// Completes when no catch-up is running.
  Future<void> whenIdle() {
    if (_running == 0) return Future.value();
    final waiter = Completer<void>();
    _idleWaiters.add(waiter);
    return waiter.future;
  }
}
