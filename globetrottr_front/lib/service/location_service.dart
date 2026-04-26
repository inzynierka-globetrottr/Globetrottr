import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../model/pending_point.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;

  Future<void> startTracking() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('No permission to access location.');
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Odkrywasz mapę w tle...",
          notificationTitle: "Globetrottr trasa",
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: "ic_notification",
            defType: "drawable",
          ),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            final point = PendingPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );

            await DatabaseHelper().insertPendingPoint(point);
            print(
              "Location saved locally: ${point.latitude}, ${point.longitude}",
            );
          },
        );
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
