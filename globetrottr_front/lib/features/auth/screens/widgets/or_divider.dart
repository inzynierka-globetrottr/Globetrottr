import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';

/// Separates the form from the other ways of signing in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      const Expanded(child: NeuDivider()),
      Text(context.l10n.authOr, style: context.typography.note),
      const Expanded(child: NeuDivider()),
    ],
  );
}
