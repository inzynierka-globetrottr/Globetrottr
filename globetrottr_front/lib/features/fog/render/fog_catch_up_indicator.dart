import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A thin progress bar shown while the fog is still being drawn from the
/// track log (after a long journey or a change of the fog format).
class FogCatchUpIndicator extends StatelessWidget {
  const FogCatchUpIndicator({super.key, required this.progress});

  final ValueListenable<double?> progress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: progress,
      builder: (context, value, _) => value == null
          ? const SizedBox.shrink()
          : LinearProgressIndicator(value: value),
    );
  }
}
