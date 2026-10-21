import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_notifier.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';

final locationProvider = NotifierProvider<LocationNotifier, TrackingState>(() {
  return LocationNotifier();
});
