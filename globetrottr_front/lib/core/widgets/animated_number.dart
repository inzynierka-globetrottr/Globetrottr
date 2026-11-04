import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A number that counts from its old value to a new one. The first value,
/// and any value that follows an unknown one, is shown at once.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.maxLines,
  });

  /// Null when unknown.
  final double? value;

  /// The whole text for a value, including the unknown one.
  final String Function(double? value) format;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null) {
      return Text(format(null), style: style, maxLines: maxLines);
    }
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: motion.long,
      curve: motion.curve,
      builder: (context, shown, _) =>
          Text(format(shown), style: style, maxLines: maxLines),
    );
  }
}
