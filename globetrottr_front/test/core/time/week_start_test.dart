import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/time/week_start.dart';

void main() {
  test('lists the Mondays of the last weeks, oldest first', () {
    expect(recentWeekStarts(DateTime(2026, 11, 4, 18), 8), [
      DateTime(2026, 9, 14),
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 2),
    ]);
  });

  test('a Monday and a Sunday start the same week', () {
    expect(recentWeekStarts(DateTime(2026, 11, 2), 1), [DateTime(2026, 11, 2)]);
    expect(recentWeekStarts(DateTime(2026, 11, 8), 1), [DateTime(2026, 11, 2)]);
  });

  test('weeks cross the end of a year', () {
    expect(recentWeekStarts(DateTime(2026, 1, 7), 2), [
      DateTime(2025, 12, 29),
      DateTime(2026, 1, 5),
    ]);
  });
}
