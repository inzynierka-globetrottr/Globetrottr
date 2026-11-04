import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/time/iso_week.dart';

void main() {
  group('isoWeekNumber', () {
    test('counts weeks from the one holding the first Thursday', () {
      expect(isoWeekNumber(DateTime(2026, 11, 4)), 45);
      expect(isoWeekNumber(DateTime(2026, 1, 2)), 1);
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1);
      expect(isoWeekNumber(DateTime(2021, 1, 3)), 53);
    });

    test('a Sunday belongs to the week that started on Monday', () {
      expect(isoWeekNumber(DateTime(2026, 11, 8)), 45);
      expect(isoWeekNumber(DateTime(2026, 11, 9)), 46);
    });
  });

  test('recentIsoWeeks lists the weeks oldest first, ending now', () {
    expect(
      recentIsoWeeks(DateTime(2026, 11, 4), 8),
      [38, 39, 40, 41, 42, 43, 44, 45],
    );
    expect(recentIsoWeeks(DateTime(2026, 1, 7), 3), [52, 1, 2]);
  });
}
