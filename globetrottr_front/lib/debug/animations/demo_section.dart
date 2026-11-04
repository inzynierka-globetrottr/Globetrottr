import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';

/// One animation to try: its title, the component and the controls under it.
class DemoSection extends StatelessWidget {
  const DemoSection({
    super.key,
    required this.title,
    required this.child,
    this.controls = const {},
  });

  final String title;
  final Widget child;

  /// Button labels and what they do.
  final Map<String, VoidCallback> controls;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        SectionHeader(title),
        NeuSurface(
          shadows: context.shadows.raised(NeoDepth.lg),
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
        if (controls.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final MapEntry(key: label, value: action)
                  in controls.entries)
                NeuPillButton(label: label, onPressed: action),
            ],
          ),
      ],
    ),
  );
}
