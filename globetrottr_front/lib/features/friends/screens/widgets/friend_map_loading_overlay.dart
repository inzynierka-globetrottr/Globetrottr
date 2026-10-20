import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

class FriendMapLoadingOverlay extends StatelessWidget {
  final bool isLoading;

  const FriendMapLoadingOverlay({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.5),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      ),
    );
  }
}
