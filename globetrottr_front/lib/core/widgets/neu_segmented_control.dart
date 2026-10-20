import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_container.dart';

class NeuSegment<T> {
  final String label;
  final T value;

  const NeuSegment({required this.label, required this.value});
}

class NeuSegmentedControl<T> extends StatelessWidget {
  final T selected;
  final ValueChanged<T> onChanged;
  final List<NeuSegment<T>> segments;
  final double width;
  final double height;

  const NeuSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.segments,
    this.width = double.infinity,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      elevation: NeuElevation.inset,
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments.map((segment) {
            final isSelected = segment.value == selected;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segment.value),
                behavior: HitTestBehavior.opaque,
                child: isSelected
                    ? NeuContainer(
                        elevation: NeuElevation.floating,
                        child: Text(
                          segment.label,
                          style: AppTextStyles.actionButtonText,
                        ),
                      )
                    : Center(
                        child: Text(
                          segment.label,
                          style: AppTextStyles.inputLabel,
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
