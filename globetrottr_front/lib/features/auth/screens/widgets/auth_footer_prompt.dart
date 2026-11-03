import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A question with a link to the other auth screen, e.g. "No account yet?
/// Create one".
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onAction,
  });

  final String prompt;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        Text(prompt, style: typography.body),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Text(
              action,
              style: typography.action.copyWith(color: context.palette.accent),
            ),
          ),
        ),
      ],
    );
  }
}
