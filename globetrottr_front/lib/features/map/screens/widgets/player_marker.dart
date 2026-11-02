import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// The player: an accent dot with a white rim. The mock-up's faint halo was
/// dropped, as it read as GPS accuracy or vision range and showed neither.
class PlayerMarker extends StatelessWidget {
  const PlayerMarker({super.key});

  /// The dot; the layer sizes the marker to it.
  static const size = 22.0;
  static const _rim = 3.5;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accent,
        shape: BoxShape.circle,
        border: Border.all(color: palette.onAccent, width: _rim),
        boxShadow: [for (final s in context.shadows.marker) s.toBoxShadow()],
      ),
    );
  }
}
