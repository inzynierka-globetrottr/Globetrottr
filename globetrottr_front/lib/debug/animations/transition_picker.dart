import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_motion_provider.dart';

/// Switches the tab and deeper screen transitions of the whole app, to
/// compare them on a phone. Temporary, until one of each is chosen.
class TransitionPicker extends ConsumerWidget {
  const TransitionPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(appMotionProvider);
    final notifier = ref.read(appMotionProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Choices(
          title: 'Tab transition',
          values: TabTransition.values,
          selected: motion.tabTransition,
          onSelected: (value) => notifier.choose(tab: value),
        ),
        _Choices(
          title: 'Deeper screen transition',
          values: DeeperTransition.values,
          selected: motion.deeperTransition,
          onSelected: (value) => notifier.choose(deeper: value),
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
