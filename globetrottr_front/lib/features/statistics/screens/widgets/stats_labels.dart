import 'package:globetrottr_front/features/statistics/logic/stats_period.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String statsPeriodLabel(
  AppLocalizations l10n,
  String locale,
  StatsPeriodRange range,
) {
  switch (range.period) {
    case StatsPeriod.week:
      final week = isoWeekOf(range.start);
      return l10n.statsWeekLabel(week.week, week.year);
    case StatsPeriod.month:
      final text = DateFormat('LLLL y', locale).format(range.start);
      return text[0].toUpperCase() + text.substring(1);
    case StatsPeriod.year:
      return '${range.start.year}';
    case StatsPeriod.allTime:
      return l10n.statsPeriodAllTime;
  }
}

/// Today, yesterday or the full date; a dash when there was no visit.
String statsVisitDateLabel(
  AppLocalizations l10n,
  String locale,
  DateTime? date, {
  DateTime? now,
}) {
  if (date == null) return '–';
  final today = now ?? DateTime.now();
  bool isDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;
  if (isDay(today)) return l10n.statsLastVisitToday;
  if (isDay(DateTime(today.year, today.month, today.day - 1))) {
    return l10n.statsVisitYesterday;
  }
  return DateFormat.yMMMMd(locale).format(date);
}
