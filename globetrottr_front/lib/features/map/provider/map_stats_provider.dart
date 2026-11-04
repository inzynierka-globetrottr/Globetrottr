import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
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

      Region? primary;
      final cachedRegionId = await statsStorage.getCachedTileRegion(
        z: tileId.z,
        x: tileId.x,
        y: tileId.y,
      );

      if (cachedRegionId != null) {
        primary = await regionStorage.findRegionById(cachedRegionId);
      }

      if (primary == null) {
        final regions = await regionStorage.findRegionsByPoint(
          lat: lat,
          lon: lon,
        );
        if (seq != _querySeq || !ref.mounted) return;

        if (regions.isNotEmpty) {
          primary = regions.first;
          await statsStorage.cacheTileRegion(
            z: tileId.z,
            x: tileId.x,
            y: tileId.y,
            regionId: primary.id,
          );
        }
      }

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
        _sessionStartTime = DateTime.now();
        state = 0.0;
      } else if (prev ?? false) {
        unawaited(ref.read(fogProvider.notifier).flush());
        if (_distanceM > 0 || _m2 > 0) {
          final durationSec = _sessionStartTime != null
              ? DateTime.now().difference(_sessionStartTime!).inSeconds
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
            _distanceM += _metersBetween(_lastPosition!, pt);
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
          for (final d in change.areaDeltas.values) {
            if (d > 0) addedM2 += d;
          }
          if (addedM2 > 0) {
            _m2 += addedM2;
            state = _m2 / 1000000.0;
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
    }
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
