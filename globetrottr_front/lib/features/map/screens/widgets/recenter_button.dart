import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

class RecenterButton extends ConsumerWidget {
  final MapController mapController;

  const RecenterButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(locationProvider).currentPosition;

    if (position == null) return const SizedBox.shrink();

    return NeuIconButton(
      onPressed: () {
        mapController.move(position, 16.0);
      },
      child: const Icon(Icons.my_location, color: Colors.white, size: 22),
    );
  }
}
