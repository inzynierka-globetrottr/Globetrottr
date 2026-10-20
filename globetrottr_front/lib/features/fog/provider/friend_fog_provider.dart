import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';

final friendFogProvider = FutureProvider.family<List<List<LatLng>>, String>(
  (ref, username) => ref.read(fogServiceProvider).getFriendFog(username),
);
