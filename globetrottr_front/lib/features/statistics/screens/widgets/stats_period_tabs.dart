import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

enum StatsPeriod {
  week,
  month,
  year,
  allTime,
}

class StatsPeriodTabs extends StatelessWidget {
  const StatsPeriodTabs({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final StatsPeriod selectedPeriod;
  final ValueChanged<StatsPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NeuSurface(
      shadows: context.shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _buildTab(context, StatsPeriod.week, l10n.statsPeriodWeek),
          const SizedBox(width: 6),
          _buildTab(context, StatsPeriod.month, l10n.statsPeriodMonth),
          const SizedBox(width: 6),
          _buildTab(context, StatsPeriod.year, l10n.statsPeriodYear),
          const SizedBox(width: 6),
          _buildTab(context, StatsPeriod.allTime, l10n.statsPeriodAllTime),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, StatsPeriod period, String label) {
    final isSelected = selectedPeriod == period;
    final palette = context.palette;
    final typography = context.typography;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPeriodChanged(period),
        child: isSelected
            ? NeuSurface(
                shadows: context.shadows.raised(NeoDepth.md),
                borderRadius: BorderRadius.circular(20),
                height: 40,
                child: Center(
                  child: Text(
                    label,
                    style: typography.action.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    label,
                    style: typography.action.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
