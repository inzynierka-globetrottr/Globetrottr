import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';

// TODO(fog): provide a tile source for the friend's fog, so BitmapFogLayer
// can draw it the same way as the own fog.
final friendFogProvider = FutureProvider.family<List<List<LatLng>>, String>(
  (ref, username) => ref.read(fogServiceProvider).getFriendFog(username),
);
