import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:latlong2/latlong.dart';

/// Where the map centres on the player: the marker, which follows the stored
/// fixes while recording, or the live fix before the marker has one.
class PlayerLocator {
  PlayerLocator(this._ref);

  final Ref _ref;

  /// Null when there is no position yet. Tracking is then started again (the
  /// permission may have been granted since) and a failure leaves its reason
  /// in `TrackingState.errorMessage`.
  Future<LatLng?> locate() async {
    final position =
        _ref.read(playerMotionProvider).value ??
        _ref.read(locationProvider).currentPosition;
    if (position != null) return position;
    await _ref.read(locationProvider.notifier).startTracking();
    return null;
  }
}

final playerLocatorProvider = Provider<PlayerLocator>(PlayerLocator.new);
