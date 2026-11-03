import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// The small spaced capitals above a section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text.toUpperCase(), style: context.typography.sectionLabel),
  );
}
