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
    } else {
      _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
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

    _dbSubscription = _broadcastStream!.listen((Position position) async {
      if (_isRecording && _sessionId != null) {
        final point = PendingPoint(
          sessionId: _sessionId!,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await _mapStorage.insertPendingPoint(point);
        await _logPosition(_sessionId!, position);
        debugPrint(
          'Location saved locally: ${point.latitude}, ${point.longitude}',
        );
      }
    });
  }

  /// Packs the newest points of the track log when a recording ends.
  Future<void> _compactLog() async {
    try {
      await _trackLog.compact();
    } on Object catch (error) {
      debugPrint('Track log compaction failed: $error');
    }
  }

  Future<void> _logPosition(String sessionId, Position position) async {
    try {
      final stored = await _trackLog.append(
        TrackLogEntry(
          sessionId: sessionId,
          timestampMs: position.timestamp.millisecondsSinceEpoch,
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
