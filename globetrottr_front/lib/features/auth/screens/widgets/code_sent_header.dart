import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// Title of a code screen and the address the code was sent to.
class CodeSentHeader extends StatelessWidget {
  const CodeSentHeader({super.key, required this.title, required this.email});

  final String title;
  final String email;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final subtitle = typography.bodyLarge.copyWith(height: 1.45);
    return Column(
      spacing: 8,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: typography.headline.copyWith(height: 1.1),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${context.l10n.authCodeSentTo}\n'),
              TextSpan(
                text: email,
                style: typography.itemTitle.copyWith(height: 1.45),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: subtitle,
        ),
      ],
    );
  }
}
