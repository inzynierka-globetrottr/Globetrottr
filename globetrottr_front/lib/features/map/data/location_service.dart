import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';

class LocationService {
  LocationService(this._mapStorage);

  final MapStorage _mapStorage;

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
    ).asBroadcastStream();

    _dbSubscription = _broadcastStream!.listen((Position position) async {
      if (_isRecording && _sessionId != null) {
        final point = PendingPoint(
          sessionId: _sessionId!,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await _mapStorage.insertPendingPoint(point);
        print('Location saved locally: ${point.latitude}, ${point.longitude}');
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

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(mapStorageProvider));
});
