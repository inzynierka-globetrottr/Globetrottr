import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A sunk track filled from the left with the accent.
class NeuProgressBar extends StatelessWidget {
  const NeuProgressBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  static const _height = 12.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_height / 2);
    return NeuSurface(
      height: _height,
      borderRadius: radius,
      shadows: context.shadows.inset(NeoDepth.xs),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.accent,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
