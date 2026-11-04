import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:latlong2/latlong.dart';

/// How much of the district around the user is discovered.
class AreaProgress {
  const AreaProgress({this.share, this.regionName});

  /// Discovered part, 0 to 1.
  final double? share;
  final String? regionName;
}

class AreaProgressNotifier extends Notifier<AreaProgress> {
  AreaProgress _current = const AreaProgress();
  FogTileId? _lastTileId;
  int _querySeq = 0;

  @override
  AreaProgress build() {
    ref.listen(statisticsRevisionProvider, (_, __) {
      final pos =
          ref.read(locationProvider).currentPosition ??
          ref.read(playerMotionProvider).value;
      if (pos != null) {
        _update(pos.latitude, pos.longitude, forceRefreshStats: true);
      }
    });

    final motion = ref.watch(playerMotionProvider);
    final pos =
        ref.watch(locationProvider.select((s) => s.currentPosition)) ??
        motion.value;
    if (pos != null) {
      _update(pos.latitude, pos.longitude);
    }
    void onMotion() {
      final p = motion.value;
      if (p != null) {
        _update(p.latitude, p.longitude);
      }
    }

    motion.addListener(onMotion);
    ref.onDispose(() => motion.removeListener(onMotion));
    return _current;
  }

  Future<void> _update(
    double lat,
    double lon, {
    bool forceRefreshStats = false,
  }) async {
    final tileId = FogTileId.fromLatLng(lat, lon, FogConfig.baseZoom);
    if (!forceRefreshStats &&
        _lastTileId == tileId &&
        _current.regionName != null) {
      return;
    }
    _lastTileId = tileId;
    final seq = ++_querySeq;

    try {
      final regionStorage = ref.read(regionStorageProvider);
      final statsStorage = ref.read(statisticsStorageProvider);

      // The tile cache belongs to the statistics tracker, which also marks
      // border tiles there; the pill asks for the point itself.
      final regions = await regionStorage.findRegionsByPoint(
        lat: lat,
        lon: lon,
      );
      final primary = regions.isEmpty ? null : regions.first;

      if (seq != _querySeq || !ref.mounted) return;

      if (primary == null) {
        _current = const AreaProgress();
        state = _current;
        return;
      }

      final stats = await statsStorage.getRegionStats(primary.id);
      if (seq != _querySeq || !ref.mounted) return;

      final share = stats != null ? (stats.discoveryPercentage / 100.0) : 0.0;

      _current = AreaProgress(share: share, regionName: primary.name);
      state = _current;
    } catch (e) {
      debugPrint('Failed to resolve area progress: $e');
    }
  }
}

final areaProgressProvider =
    NotifierProvider<AreaProgressNotifier, AreaProgress>(
      AreaProgressNotifier.new,
    );

class SessionNewAreaNotifier extends Notifier<double?> {
  double _m2 = 0.0;
  double _distanceM = 0.0;
  DateTime? _sessionStartTime;
  LatLng? _lastPosition;
  StreamSubscription<FogChange>? _changesSub;
  StreamSubscription<TrackLogEntry>? _loggedSub;
  DateTime? _day;
  double _dayDistanceM = 0.0;
  double _dayAreaM2 = 0.0;
  bool _dayCounted = false;

  static const double _metersPerDegree = 111319.9;

  @override
  double? build() {
    ref.listen(locationProvider.select((s) => s.isRecording), (
      prev,
      recording,
    ) {
      if (recording) {
        _m2 = 0.0;
        _distanceM = 0.0;
        _lastPosition = null;
        _sessionStartTime = ref.read(clockProvider)();
        _day = null;
        state = 0.0;
      } else if (prev ?? false) {
        unawaited(ref.read(fogProvider.notifier).flush());
        if (_distanceM > 0 || _m2 > 0) {
          final durationSec = _sessionStartTime != null
              ? ref
                    .read(clockProvider)()
                    .difference(_sessionStartTime!)
                    .inSeconds
              : 0;
          try {
            ref
                .read(statisticsTrackerProvider)
                .recordTripSession(
                  distanceM: _distanceM,
                  durationSeconds: durationSec,
                  activityType: 'walk',
                )
                .catchError((Object error) {
                  debugPrint('Failed to record trip session: $error');
                });
          } catch (e) {
            debugPrint('Failed to record trip session: $e');
          }
        }
        _m2 = 0.0;
        _distanceM = 0.0;
        _lastPosition = null;
        _sessionStartTime = null;
        state = null;
      }
    });

    ref.listen(fogProvider, (_, next) {
      next.whenData((source) => _attach(source.store));
    });

    final currentFog = ref.watch(fogProvider).asData?.value;
    if (currentFog != null) {
      _attach(currentFog.store);
    }

    try {
      final locService = ref.read(locationServiceProvider);
      _loggedSub = locService.loggedPoints.listen((entry) {
        final isRecording = ref.read(locationProvider).isRecording;
        if (isRecording) {
          final pt = LatLng(entry.latitude, entry.longitude);
          if (_lastPosition != null) {
            final step = _metersBetween(_lastPosition!, pt);
            _distanceM += step;
            _accrue(distanceM: step);
          }
          _lastPosition = pt;
        }
      });
    } catch (_) {}

    ref.onDispose(() {
      _changesSub?.cancel();
      _loggedSub?.cancel();
    });
    return null;
  }

  void _attach(FogStore store) {
    _changesSub?.cancel();
    _changesSub = store.changes.listen((change) {
      try {
        final isRecording = ref.read(locationProvider).isRecording;
        if (isRecording && change.areaDeltas.isNotEmpty) {
          var addedM2 = 0.0;
          for (final cells in change.areaDeltas.values) {
            addedM2 += cells.total;
          }
          if (addedM2 > 0) {
            _m2 += addedM2;
            state = _m2 / 1000000.0;
            _accrue(areaM2: addedM2);
          }
        }
      } catch (e) {
        debugPrint('Failed to update session new area: $e');
      }
    });
  }

  static double _metersBetween(LatLng a, LatLng b) {
    final north = (b.latitude - a.latitude) * _metersPerDegree;
    final east =
        (b.longitude - a.longitude) *
        _metersPerDegree *
        math.cos(a.latitude * math.pi / 180);
    return math.sqrt(north * north + east * east);
  }

  void addAreaM2(double m2) {
    if (m2 > 0) {
      _m2 += m2;
      state = _m2 / 1000000.0;
      _accrue(areaM2: m2);
    }
  }

  /// Counts today as a recording day as soon as today's part of the
  /// recording passes the streak threshold, so a recording that the app
  /// never sees stop, or one across midnight, still counts.
  void _accrue({double distanceM = 0, double areaM2 = 0}) {
    final now = ref.read(clockProvider)();
    final day = _day;
    if (day == null ||
        day.year != now.year ||
        day.month != now.month ||
        day.day != now.day) {
      _day = now;
      _dayDistanceM = 0.0;
      _dayAreaM2 = 0.0;
      _dayCounted = false;
    }
    _dayDistanceM += distanceM;
    _dayAreaM2 += areaM2;
    if (_dayCounted) return;
    if (_dayDistanceM < StreakService.minDistanceForRecordingStreak &&
        _dayAreaM2 < StreakService.minAreaForRecordingStreak) {
      return;
    }
    _dayCounted = true;
    ref.read(statisticsTrackerProvider).recordRecordingDay(now: now).catchError(
      (Object error) {
        debugPrint('Failed to record the recording day: $error');
      },
    );
  }

  void reset() {
    _m2 = 0.0;
    state = null;
  }
}

final sessionNewAreaProvider =
    NotifierProvider<SessionNewAreaNotifier, double?>(
      SessionNewAreaNotifier.new,
    );
