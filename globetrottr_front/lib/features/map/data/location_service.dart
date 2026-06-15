import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_storage.dart';
import 'pending_point.dart';

// TODO: potentially refactor this, as well as map storage to not be singletons, and instead make use of riverpod providers
class LocationService {
  StreamSubscription<Position>? _dbSubscription;
  Stream<Position>? _broadcastStream;

  late LocationSettings _locationSettings;
  bool _isRecording = false;
  String? _sessionId;

  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Stream<Position> get positionStream {
    if (_broadcastStream == null) {
      throw Exception(
        'Localization stream not initiated, call startTracking() first.',
      );
    }
    return _broadcastStream!;
  }

  void setRecording(bool value) {
    _isRecording = value;
    if (value && _sessionId == null) {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> startTracking() async {
    if (_broadcastStream != null) return;

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('No permission to access location.');
      }
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConfig.distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Recording your route in the background...",
          notificationTitle: "Globetrottr",
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: "ic_notification",
            defType: "drawable",
          ),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapConfig.distanceFilter,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
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
    ).asBroadcastStream();

    _dbSubscription = _broadcastStream!.listen((Position position) async {
      if (_isRecording && _sessionId != null) {
        final point = PendingPoint(
          sessionId: _sessionId!,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await MapStorage().insertPendingPoint(point);
        print("Location saved locally: ${point.latitude}, ${point.longitude}");
      }
    });
  }

  void stopTracking() {
    _dbSubscription?.cancel();
    _dbSubscription = null;
    _broadcastStream = null;
    _sessionId = null;
    _isRecording = false;
  }
}
