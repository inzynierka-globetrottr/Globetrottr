import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:latlong2/latlong.dart';

class _Waypoint {
  const _Waypoint(this.at, this.entry);

  final LatLng at;
  final TrackLogEntry? entry;
}

/// The position of the player as it is drawn. It glides along the recorded
/// fixes frame by frame instead of jumping to each new one, and everything on
/// the map that follows the player reads this one value, so the marker and
/// the fog can never be apart.
///
/// [ValueListenable] is Flutter's interface for "a value that tells you when
/// it changed"; listeners are called once per animation frame.
class PlayerMotion extends ChangeNotifier implements ValueListenable<LatLng?> {
  PlayerMotion({bool Function()? animates, this._clock})
    : _animates = animates ?? _appIsVisible;

  static const Duration _shortestInterval = Duration(milliseconds: 200);
  static const Duration _longestInterval = Duration(seconds: 3);

  /// Share of the newest gap between fixes in the running estimate.
  static const double _intervalWeight = 0.3;

  static bool _appIsVisible() {
    return SchedulerBinding.instance.lifecycleState ==
        AppLifecycleState.resumed;
  }

  final bool Function() _animates;
  final Duration Function()? _clock;
  final Stopwatch _watch = Stopwatch()..start();
  final Queue<_Waypoint> _route = Queue();

  // `sync` delivers an event during the frame that passes the point, so what
  // is drawn in this frame already knows about it.
  final StreamController<TrackLogEntry> _passed =
      StreamController<TrackLogEntry>.broadcast(sync: true);

  LatLng? _position;
  double _metersPerSecond = 0;
  double _intervalSeconds = 1;
  Duration? _lastFix;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  @override
  LatLng? get value => _position;

  /// Track log entries the player has reached, in order.
  Stream<TrackLogEntry> get passed => _passed.stream;

  /// Adds the next fix of the route. An [entry] is passed on when the player
  /// gets there.
  void moveTo(LatLng to, {TrackLogEntry? entry}) {
    final now = _clock?.call() ?? _watch.elapsed;
    final last = _lastFix;
    _lastFix = now;
    final from = _route.isEmpty ? _position : _route.last.at;
    final gapped =
        from == null || _metersBetween(from, to) > MapConfig.maxPathGapMeters;
    if (gapped || !_animates()) {
      finish();
      _position = to;
      if (entry != null) _passed.add(entry);
      notifyListeners();
      return;
    }

    if (last != null) _noteInterval(now - last);
    _route.add(_Waypoint(to, entry));
    _metersPerSecond = _metersLeft() / _intervalSeconds;
    _startTicking();
  }

  void _noteInterval(Duration gap) {
    final seconds =
        gap.inMicroseconds.clamp(
          _shortestInterval.inMicroseconds,
          _longestInterval.inMicroseconds,
        ) /
        Duration.microsecondsPerSecond;
    _intervalSeconds += (seconds - _intervalSeconds) * _intervalWeight;
  }

  double _metersLeft() {
    var total = 0.0;
    var at = _position!;
    for (final waypoint in _route) {
      total += _metersBetween(at, waypoint.at);
      at = waypoint.at;
    }
    return total;
  }

  /// Moves the player along the route by the time of one frame.
  void advance(Duration by) {
    if (_route.isEmpty) return;
    var left =
        _metersPerSecond * by.inMicroseconds / Duration.microsecondsPerSecond;
    var at = _position!;
    while (_route.isNotEmpty) {
      final next = _route.first;
      final leg = _metersBetween(at, next.at);
      if (leg > left) {
        final share = left / leg;
        at = LatLng(
          at.latitude + (next.at.latitude - at.latitude) * share,
          at.longitude + (next.at.longitude - at.longitude) * share,
        );
        break;
      }
      left -= leg;
      at = next.at;
      _route.removeFirst();
      final entry = next.entry;
      _position = at;
      if (entry != null) _passed.add(entry);
    }
    _position = at;
    notifyListeners();
    if (_route.isEmpty) _ticker?.stop();
  }

  /// Passes the rest of the route at once, for when no frames will follow or
  /// the recording ends.
  void finish() {
    if (_route.isEmpty) return;
    _ticker?.stop();
    final route = _route.toList();
    _route.clear();
    for (final waypoint in route) {
      _position = waypoint.at;
      final entry = waypoint.entry;
      if (entry != null) _passed.add(entry);
    }
    notifyListeners();
  }

  void _startTicking() {
    final ticker = _ticker ??= Ticker(_onTick, debugLabel: 'PlayerMotion');
    if (ticker.isActive) return;
    _lastTick = Duration.zero;
    unawaited(ticker.start().orCancel.catchError((Object _) {}));
  }

  void _onTick(Duration elapsed) {
    final by = elapsed - _lastTick;
    _lastTick = elapsed;
    advance(by);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    unawaited(_passed.close());
    super.dispose();
  }

  /// Plain flat-earth distance; the legs are only a few meters long.
  static double _metersBetween(LatLng a, LatLng b) {
    const metersPerDegree = 111195.0;
    final north = (b.latitude - a.latitude) * metersPerDegree;
    final east =
        (b.longitude - a.longitude) *
        metersPerDegree *
        math.cos(a.latitude * math.pi / 180);
    return math.sqrt(north * north + east * east);
  }
}

/// Feeds the motion: while recording from the stored fixes, so a fix reaches
/// the fog only after it is safe in the track log; otherwise from the live
/// position.
final playerMotionProvider = Provider<PlayerMotion>((ref) {
  final motion = PlayerMotion();
  final logged = ref.read(locationServiceProvider).loggedPoints.listen((entry) {
    motion.moveTo(LatLng(entry.latitude, entry.longitude), entry: entry);
  });
  ref.listen(locationProvider.select((s) => s.currentPosition), (_, position) {
    final recording = ref.read(locationProvider).isRecording;
    if (position != null && !recording) motion.moveTo(position);
  });
  ref.onDispose(() {
    unawaited(logged.cancel());
    motion.dispose();
  });
  return motion;
});
