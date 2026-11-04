import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

/// The password rules as small pills in one row: filled with the accent and
/// ticked once the password meets the rule, sunk in and crossed until then.
/// The length pill takes a double share of the width for its longer label;
/// on a narrow screen the labels shrink rather than wrap.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      spacing: 6,
      children: [
        for (final rule in PasswordRule.values)
          Expanded(
            flex: rule == PasswordRule.length ? 2 : 1,
            child: _RuleChip(rule: rule, met: rule.isMetBy(password)),
          ),
      ],
    ),
  );
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.rule, required this.met});

  final PasswordRule rule;
  final bool met;

  static const _height = 28.0;

  String _label(AppLocalizations l10n) => switch (rule) {
    PasswordRule.length => l10n.authRuleLength(
      PasswordRule.minLength,
      PasswordRule.maxLength,
    ),
    PasswordRule.lowercase => l10n.authRuleLowercase,
    PasswordRule.uppercase => l10n.authRuleUppercase,
    PasswordRule.digit => l10n.authRuleDigit,
    PasswordRule.special => l10n.authRuleSpecial,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final shadows = context.shadows;
    final motion = context.motion;
    final label = _label(l10n);
    return Semantics(
      label: '$label, ${met ? l10n.authRuleMet : l10n.authRuleNotMet}',
      excludeSemantics: true,
      // The pill fills with the accent and the tick pops in once the rule
      // is met, and the other way round.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: met ? 1 : 0),
        duration: motion.short,
        curve: motion.curve,
        builder: (context, fill, _) {
          final color = Color.lerp(palette.textMuted, palette.onAccent, fill);
          return NeuSurface(
            shadows: lerpShadows(
              shadows.inset(NeoDepth.xs),
              shadows.raisedAccent(NeoDepth.xs),
              fill,
            ),
            color: Color.lerp(palette.background, palette.accent, fill),
            borderRadius: BorderRadius.circular(_height / 2),
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  AnimatedSwitcher(
                    duration: motion.short,
                    switchInCurve: motion.popCurve,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: AppIcon(
                      met ? AppIcons.check : AppIcons.close,
                      key: ValueKey(met),
                      size: 12,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style:
                        (met
                                ? context.typography.captionStrong
                                : context.typography.caption)
                            .copyWith(color: color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
