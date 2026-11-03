import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_layer.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';

/// The fog view of the map: the user's own fog, revealed up to the player
/// while recording. Place it among the children of a `FlutterMap`.
class FogViewLayer extends ConsumerWidget {
  const FogViewLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(locationProvider.select((s) => s.isRecording));
    final motion = ref.watch(playerMotionProvider);
    return BitmapFogLayer(
      source: ref.watch(fogProvider).value,
      options: ref.watch(fogRenderOptionsProvider),
      head: recording ? motion : null,
    );
  }
}
