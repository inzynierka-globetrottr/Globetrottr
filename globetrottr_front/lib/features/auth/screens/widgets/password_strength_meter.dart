import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

/// Three bars filled by the strength of the password, with the rules under
/// them.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  static const _bars = 3;

  int get _filled => switch (strength) {
    PasswordStrength.none => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.good => 2,
    PasswordStrength.strong => 3,
  };

  String? _level(AppLocalizations l10n) => switch (strength) {
    PasswordStrength.none => null,
    PasswordStrength.weak => l10n.authPasswordWeak,
    PasswordStrength.good => l10n.authPasswordGood,
    PasswordStrength.strong => l10n.authPasswordStrong,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    final level = _level(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            children: [
              for (var i = 0; i < _bars; i++)
                Expanded(child: _Bar(filled: i < _filled)),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                if (level != null) ...[
                  TextSpan(text: '${l10n.authPasswordStrength} '),
                  TextSpan(text: level, style: typography.captionStrong),
                  const TextSpan(text: ' · '),
                ],
                TextSpan(text: l10n.authPasswordRules),
              ],
            ),
            style: typography.caption,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;
    return NeuSurface(
      shadows: filled ? shadows.shade(NeoDepth.xs) : shadows.inset(NeoDepth.sm),
      color: filled ? context.palette.accent : null,
      borderRadius: BorderRadius.circular(5),
      height: 10,
    );
  }
}
