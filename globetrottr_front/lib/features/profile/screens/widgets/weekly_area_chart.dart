import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/core/time/week_start.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// New area per week as bars, oldest first; the current week is the last
/// one, in gold. A week is labelled with the day its Monday falls on, and
/// with the month where the month changes.
class WeeklyAreaChart extends ConsumerWidget {
  const WeeklyAreaChart({super.key, required this.weeklyKm2});

  /// Null for a week whose area is unknown.
  final List<double?> weeklyKm2;

  static const _plotHeight = 96.0;
  static const _maxBar = 72.0;
  static const _minBar = 4.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    final weeks = recentWeekStarts(
      ref.watch(clockProvider)(),
      weeklyKm2.length,
    );
    final known = weeklyKm2.whereType<double>();
    final top = known.isEmpty ? 0.0 : known.reduce(math.max);
    final last = weeklyKm2.length - 1;
    final strong = typography.smallStrong.copyWith(color: palette.text);
    final tabular = strong.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget bar(int i) {
      final km2 = weeklyKm2[i];
      final area = formatKm2(km2, locale);
      return Semantics(
        label: i == last
            ? l10n.profileThisWeekValue(area)
            : l10n.profileWeekValue(formatShortDate(weeks[i], locale), area),
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 4,
          children: [
            Text(area, style: tabular, maxLines: 1),
            if (km2 != null && km2 > 0 && top > 0)
              NeuSurface(
                width: double.infinity,
                height: math.max(_minBar, km2 / top * _maxBar),
                borderRadius: BorderRadius.circular(7),
                color: i == last ? palette.gold : palette.accent,
                shadows: context.shadows.raisedAccent(NeoDepth.xs),
              ),
          ],
        ),
      );
    }

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.profileWeeklyTitle, style: typography.value),
              ),
              Text(l10n.profileWeeklyUnit, style: typography.caption),
            ],
          ),
          SizedBox(
            height: _plotHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: _gap,
              children: [
                for (var i = 0; i < weeklyKm2.length; i++)
                  Expanded(child: bar(i)),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: _gap,
              children: [
                for (var i = 0; i < weeks.length; i++)
                  Expanded(
                    child: i == last
                        ? Text(
                            l10n.profileWeekNow,
                            textAlign: TextAlign.center,
                            style: strong,
                          )
                        : _WeekLabel(
                            day: '${weeks[i].day}',
                            month:
                                i == 0 || weeks[i].month != weeks[i - 1].month
                                ? formatShortMonth(weeks[i], locale)
                                : null,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The day of a week's Monday, with the month under it when given. The
/// month line keeps its height, so all days sit on one line.
class _WeekLabel extends StatelessWidget {
  const _WeekLabel({required this.day, this.month});

  final String day;
  final String? month;

  static const _lineHeight = 1.2;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final monthStyle = typography.smallStrong.copyWith(
      color: context.palette.text,
      height: _lineHeight,
    );
    return Column(
      children: [
        Text(
          day,
          style: typography.small.copyWith(
            height: _lineHeight,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(month ?? '', style: monthStyle, maxLines: 1),
      ],
    );
  }
}
