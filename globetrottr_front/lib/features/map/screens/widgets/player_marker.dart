import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

class PlayerMarker extends StatelessWidget {
  const PlayerMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accent,
        shape: BoxShape.circle,
        border: Border.all(color: palette.onAccent, width: 3),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
