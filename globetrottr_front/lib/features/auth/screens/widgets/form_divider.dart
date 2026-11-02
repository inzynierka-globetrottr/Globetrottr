import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';

class FormDivider extends StatelessWidget {
  const FormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        const Expanded(child: NeuDivider()),
        Text(context.l10n.authOrContinueWith, style: context.typography.note),
        const Expanded(child: NeuDivider()),
      ],
    );
  }
}
