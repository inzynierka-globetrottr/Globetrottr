import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// The player: an accent dot with a white rim in a faint accent halo.
class PlayerMarker extends StatelessWidget {
  const PlayerMarker({super.key});

  /// The halo; the layer sizes the marker to it.
  static const size = 44.0;
  static const _dot = 22.0;
  static const _rim = 3.5;
  static const _haloOpacity = 0.18;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: _haloOpacity),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(
            color: palette.accent,
            shape: BoxShape.circle,
            border: Border.all(color: palette.onAccent, width: _rim),
            boxShadow: [
              for (final s in context.shadows.marker) s.toBoxShadow(),
            ],
          ),
        ),
      ),
    );
  }
}
