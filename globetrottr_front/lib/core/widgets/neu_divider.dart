import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A groove: a 2 px line with a lit edge under it (or to its right when
/// vertical).
class NeuDivider extends StatelessWidget {
  const NeuDivider({super.key, this.length}) : _vertical = false;

  const NeuDivider.vertical({super.key, this.length}) : _vertical = true;

  static const _thickness = 2.0;

  /// Fills the available space when null.
  final double? length;
  final bool _vertical;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: _vertical ? _thickness : length ?? double.infinity,
      height: _vertical ? length ?? double.infinity : _thickness,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.divider,
          boxShadow: [
            BoxShadow(
              color: palette.dividerHighlight,
              offset: _vertical ? const Offset(1, 0) : const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
