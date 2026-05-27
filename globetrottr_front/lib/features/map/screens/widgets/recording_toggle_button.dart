import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/theme/app_colors.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

class RecordingToggleButton extends ConsumerWidget {
  const RecordingToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);

    if (!state.isTracking) return const SizedBox.shrink();

    return NeuIconButton(
      onPressed: () {
        ref.read(locationProvider.notifier).setRecording(!state.isRecording);
      },
      child: Icon(
        state.isRecording ? Icons.radio_button_checked : Icons.radio_button_off,
        color: state.isRecording ? AppColors.accentRed : AppColors.textLight,
        size: 22,
      ),
    );
  }
}
