import 'package:flutter/foundation.dart';

enum StatsPeriod { week, month, year, allTime }

/// The ISO 8601 week of [date] and the year that week belongs to, which
/// differs from the calendar year for a few days around New Year.
({int week, int year}) isoWeekOf(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final dayOfYear = thursday.difference(DateTime.utc(thursday.year)).inDays;
  return (week: dayOfYear ~/ 7 + 1, year: thursday.year);
}

/// The days a statistics period covers, both ends included, at local
/// midnight.
@immutable
class StatsPeriodRange {
  const StatsPeriodRange({
    required this.period,
    required this.start,
    required this.end,
  });

  final StatsPeriod period;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is StatsPeriodRange &&
      other.period == period &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(period, start, end);
}

StatsPeriodRange statsPeriodRange(StatsPeriod period, DateTime anchor) {
  switch (period) {
    case StatsPeriod.week:
      final monday = DateTime(
        anchor.year,
        anchor.month,
        anchor.day - (anchor.weekday - DateTime.monday),
      );
      return StatsPeriodRange(
        period: period,
        start: monday,
        end: DateTime(monday.year, monday.month, monday.day + 6),
      );
    case StatsPeriod.month:
      return StatsPeriodRange(
        period: period,
        start: DateTime(anchor.year, anchor.month),
        end: DateTime(anchor.year, anchor.month + 1, 0),
      );
    case StatsPeriod.year:
      return StatsPeriodRange(
        period: period,
        start: DateTime(anchor.year),
        end: DateTime(anchor.year, 12, 31),
      );
    case StatsPeriod.allTime:
      return StatsPeriodRange(
        period: period,
        start: DateTime(1970),
        end: DateTime(2099, 12, 31),
      );
  }
}

/// [anchor] moved by [steps] whole periods. Calendar arithmetic, so a DST
/// change cannot move it to another day.
DateTime shiftStatsPeriod(StatsPeriod period, DateTime anchor, int steps) {
  switch (period) {
    case StatsPeriod.week:
      return DateTime(anchor.year, anchor.month, anchor.day + 7 * steps);
    case StatsPeriod.month:
      return DateTime(anchor.year, anchor.month + steps);
    case StatsPeriod.year:
      return DateTime(anchor.year + steps);
    case StatsPeriod.allTime:
      return anchor;
  }
}
