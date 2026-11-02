import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class NeuSegment<T> {
  final String label;
  final T value;

  const NeuSegment({required this.label, required this.value});
}

/// Tabs sunk into the page; the selected one is raised and in the accent.
class NeuSegmentedControl<T> extends StatelessWidget {
  final T selected;
  final ValueChanged<T> onChanged;
  final List<NeuSegment<T>> segments;

  const NeuSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return NeuSurface(
      shadows: context.shadows.inset(NeoDepth.sm),
      borderRadius: BorderRadius.circular(24),
      height: 52,
      padding: const EdgeInsets.all(5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final segment in segments)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segment.value),
                behavior: HitTestBehavior.opaque,
                child: segment.value == selected
                    ? NeuSurface(
                        shadows: context.shadows.raised(NeoDepth.md),
                        borderRadius: BorderRadius.circular(19),
                        child: Center(
                          child: Text(
                            segment.label,
                            style: typography.label.copyWith(
                              color: context.palette.accent,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(segment.label, style: typography.note),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
