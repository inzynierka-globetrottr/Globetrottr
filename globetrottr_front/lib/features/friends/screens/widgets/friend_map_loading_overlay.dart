import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

class FriendMapLoadingOverlay extends StatelessWidget {
  final bool isLoading;

  const FriendMapLoadingOverlay({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    final palette = context.palette;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.background.withValues(alpha: 0.5),
        child: Center(
          child: CircularProgressIndicator(color: palette.accent),
        ),
      ),
    );
  }
}
