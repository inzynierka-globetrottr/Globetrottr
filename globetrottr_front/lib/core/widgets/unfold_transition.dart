import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Grows [child] downwards from nothing to its full height as the size factor
/// goes from 0 to 1. Unlike [SizeTransition] it clips only while it moves,
/// so the shadows of a card in place are not cut off at its edges.
class UnfoldTransition extends AnimatedWidget {
  const UnfoldTransition({
    super.key,
    required Animation<double> sizeFactor,
    required this.child,
    this.fitWidth = false,
  }) : super(listenable: sizeFactor);

  final Widget child;

  /// As wide as [child] instead of as wide as allowed.
  final bool fitWidth;

  @override
  Widget build(BuildContext context) {
    final factor = (listenable as Animation<double>).value;
    return ClipRect(
      clipBehavior: factor < 1 ? Clip.hardEdge : Clip.none,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: math.max(factor, 0),
        widthFactor: fitWidth ? 1 : null,
        child: child,
      ),
    );
  }
}
