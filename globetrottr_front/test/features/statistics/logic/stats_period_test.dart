import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/statistics/logic/stats_period.dart';

void main() {
  group('isoWeekOf', () {
    test('a Monday at the end of December can be week 1 of the next year', () {
      expect(isoWeekOf(DateTime(2025, 12, 29)), (week: 1, year: 2026));
    });

    test('New Year can still be week 53 of the previous year', () {
      expect(isoWeekOf(DateTime(2027)), (week: 53, year: 2026));
    });

    test('a day in the middle of the year', () {
      expect(isoWeekOf(DateTime(2026, 11, 4)), (week: 45, year: 2026));
    });
  });

  group('statsPeriodRange', () {
    test('a month runs from its first to its last day', () {
      final range = statsPeriodRange(StatsPeriod.month, DateTime(2026, 2, 15));

      expect(range.start, DateTime(2026, 2));
      expect(range.end, DateTime(2026, 2, 28));
    });

    test('a week runs from Monday to Sunday', () {
      final range = statsPeriodRange(
        StatsPeriod.week,
        DateTime(2026, 11, 4, 18),
      );

      expect(range.start, DateTime(2026, 11, 2));
      expect(range.end, DateTime(2026, 11, 8));
    });

    test('a year runs from the first of January to the last of December', () {
      final range = statsPeriodRange(StatsPeriod.year, DateTime(2026, 7));

      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2026, 12, 31));
    });

    test('ranges with the same period and days are equal', () {
      expect(
        statsPeriodRange(StatsPeriod.month, DateTime(2026, 10, 3)),
        statsPeriodRange(StatsPeriod.month, DateTime(2026, 10, 28, 23)),
      );
    });
  });

  group('shiftStatsPeriod', () {
    test('a week back across a DST change lands on the previous Monday', () {
      final shifted = shiftStatsPeriod(
        StatsPeriod.week,
        DateTime(2026, 3, 30, 0, 30),
        -1,
      );

      expect((shifted.year, shifted.month, shifted.day), (2026, 3, 23));
    });

    test('a month forward from January lands in February', () {
      final shifted = shiftStatsPeriod(
        StatsPeriod.month,
        DateTime(2026, 1, 31),
        1,
      );

      expect((shifted.year, shifted.month), (2026, 2));
    });

    test('all time does not move', () {
      final anchor = DateTime(2026, 5, 5);

      expect(shiftStatsPeriod(StatsPeriod.allTime, anchor, -1), anchor);
    });
  });
}
