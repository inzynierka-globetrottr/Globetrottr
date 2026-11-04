import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class StatsDateNavigator extends StatelessWidget {
  const StatsDateNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.canGoNext = true,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final l10n = context.l10n;

    return Row(
      children: [
        GestureDetector(
          onTap: onPrevious,
          child: Semantics(
            button: true,
            label: l10n.statsPrevPeriod,
            child: NeuSurface.circle(
              size: 44,
              shadows: context.shadows.raised(NeoDepth.md),
              child: Center(
                child: AppIcon(
                  AppIcons.chevronLeft,
                  color: palette.text,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: typography.valueLarge,
          ),
        ),
        GestureDetector(
          onTap: canGoNext ? onNext : null,
          child: Semantics(
            button: true,
            enabled: canGoNext,
            label: l10n.statsNextPeriod,
            child: NeuSurface.circle(
              size: 44,
              shadows: canGoNext
                  ? context.shadows.raised(NeoDepth.md)
                  : context.shadows.inset(NeoDepth.sm),
              child: Center(
                child: AppIcon(
                  AppIcons.chevronRight,
                  color: canGoNext ? palette.text : palette.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
