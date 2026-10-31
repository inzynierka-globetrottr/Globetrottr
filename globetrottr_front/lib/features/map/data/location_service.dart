import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

class LocationService {
  LocationService(this._mapStorage, this._trackLog);

  final MapStorage _mapStorage;
  final TrackLogStorage _trackLog;
  final StreamController<TrackLogEntry> _logged =
      StreamController<TrackLogEntry>.broadcast();

  StreamSubscription<Position>? _dbSubscription;
  Stream<Position>? _broadcastStream;

  late LocationSettings _locationSettings;
  bool _isRecording = false;
  String? _sessionId;
  Position? _lastPosition;

  Stream<Position> get positionStream {
    if (_broadcastStream == null) {
      throw StateError(
        'Localization stream not initiated, call startTracking() first.',
      );
    }
    return _broadcastStream!;
  }

  /// False for fixes that are not real coordinates (NaN, infinite or out of
  /// range). Such a value would break the map camera and the fog tile maths,
  /// so it never leaves this service.
  static bool isUsablePosition(Position position) {
    final lat = position.latitude;
    final lng = position.longitude;
    return lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180;
  }

  String? get sessionId => _sessionId;

  /// Every recorded position after it was stored in the permanent track log,
  /// with its log id assigned.
  Stream<TrackLogEntry> get loggedPoints => _logged.stream;

  void setRecording(bool value) {
    _isRecording = value;
    if (!value) {
      _sessionId = null;
      unawaited(_compactLog());
    } else if (_sessionId == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionId = now.toString();
      _sessionId = sessionId;
      // The stream is silent until the user moves, so the recording starts
      // from the position the map shows, at the moment it was started.
      final start = _lastPosition;
      if (start != null) unawaited(_store(sessionId, start, now));
    }
  }

  Future<void> startTracking() async {
    if (_broadcastStream != null) return;

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are disabled. Please enable them in your device settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Location permission is required to track your trips.',
        );
      }
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConfig.distanceFilter,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Recording your route in the background...',
          notificationTitle: 'Globetrottr',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_notification',
          ),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConfig.distanceFilter,
        activityType: ActivityType.fitness,
        showBackgroundLocationIndicator: true,
      );
    } else {
      _locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConfig.distanceFilter,
      );
    }

    _broadcastStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).where(isUsablePosition).asBroadcastStream();

    _dbSubscription = _broadcastStream!.listen(recordPosition);
  }

  /// Stores a fix in the session that was recording when it arrived, even if
  /// recording stops while it is being written.
  ///
  /// Method is public for testing purposes, but should not be called from outside the service. (debatable decision)
  @visibleForTesting
  Future<void> recordPosition(Position position) async {
    _lastPosition = position;
    final sessionId = _sessionId;
    if (!_isRecording || sessionId == null) return;

    await _store(
      sessionId,
      position,
      position.timestamp.millisecondsSinceEpoch,
    );
  }

  Future<void> _store(
    String sessionId,
    Position position,
    int timestampMs,
  ) async {
    final point = PendingPoint(
      sessionId: sessionId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: timestampMs,
    );
    try {
      await _mapStorage.insertPendingPoint(point);
    } on Object catch (error) {
      debugPrint('Pending point write failed: $error');
    }
    await _logPosition(sessionId, position, timestampMs);
  }

  /// Packs the newest points of the track log when a recording ends.
  Future<void> _compactLog() async {
    try {
      await _trackLog.compact();
    } on Object catch (error) {
      debugPrint('Track log compaction failed: $error');
    }
  }

  Future<void> _logPosition(
    String sessionId,
    Position position,
    int timestampMs,
  ) async {
    try {
      final stored = await _trackLog.append(
        TrackLogEntry(
          sessionId: sessionId,
          timestampMs: timestampMs,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy > 0 ? position.accuracy : null,
          speed: position.speed >= 0 ? position.speed : null,
        ),
      );
      if (!_logged.isClosed) _logged.add(stored);
    } on Object catch (error) {
      debugPrint('Track log write failed: $error');
    }
  }

  void stopTracking() {
    _dbSubscription?.cancel();
    _dbSubscription = null;
    _broadcastStream = null;
    _sessionId = null;
    _isRecording = false;
    _lastPosition = null;
    unawaited(_compactLog());
  }

  Future<void> dispose() async {
    stopTracking();
    await _logged.close();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService(
    ref.watch(mapStorageProvider),
    ref.watch(trackLogStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
