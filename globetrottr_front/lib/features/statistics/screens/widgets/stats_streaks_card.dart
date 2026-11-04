import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class StatsStreaksCard extends StatelessWidget {
  const StatsStreaksCard({
    super.key,
    required this.openStreakDays,
    required this.maxOpenStreakDays,
    required this.recordingStreakDays,
    required this.maxRecordingStreakDays,
  });

  final int openStreakDays;
  final int maxOpenStreakDays;
  final int recordingStreakDays;
  final int maxRecordingStreakDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _StreakTile(
            icon: Icons.calendar_today_rounded,
            label: l10n.statsAppOpenStreak,
            days: openStreakDays,
            maxDays: maxOpenStreakDays,
            isAccent: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StreakTile(
            icon: Icons.local_fire_department_rounded,
            label: l10n.statsRecordingStreak,
            days: recordingStreakDays,
            maxDays: maxRecordingStreakDays,
            isAccent: true,
          ),
        ),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({
    required this.icon,
    required this.label,
    required this.days,
    required this.maxDays,
    required this.isAccent,
  });

  final IconData icon;
  final String label;
  final int days;
  final int maxDays;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final l10n = context.l10n;

    return NeuSurface(
      shadows: context.shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isAccent ? palette.accent : palette.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statsStreakDays(days),
            maxLines: 1,
            style: typography.statValue.copyWith(
              letterSpacing: -0.02 * 20,
              color: isAccent ? palette.accent : palette.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.statsStreakMax(maxDays),
            maxLines: 1,
            style: typography.small.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
