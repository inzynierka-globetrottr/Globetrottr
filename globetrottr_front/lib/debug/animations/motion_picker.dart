import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_motion_provider.dart';

/// Switches the variants of the motion of the whole app, to compare them on
/// a phone. Temporary, until one of each is chosen.
class MotionPicker extends ConsumerWidget {
  const MotionPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(motionChoicesProvider);
    final notifier = ref.read(motionChoicesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Choices(
          title: 'Durations (quick: 150/180/220 ms, mockup: 200/240/280 ms)',
          values: MotionPace.values,
          selected: chosen.pace,
          onSelected: (value) => notifier.choose(pace: value),
        ),
        _Choices(
          title: 'Button rising back',
          values: PressFeel.values,
          selected: chosen.press,
          onSelected: (value) => notifier.choose(press: value),
        ),
      ],
    );
  }
}

class _Choices<T extends Enum> extends StatelessWidget {
  const _Choices({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(value.name),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    ),
  );
}
