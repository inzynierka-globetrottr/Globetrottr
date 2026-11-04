import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';

void main() {
  group('weekly area', () {
    test('every shown week is unknown without data', () {
      expect(
        const ProfileStats().weeklyKm2,
        List<double?>.filled(ProfileStats.weeksShown, null),
      );
    });

    test('missing older weeks are unknown, the current week stays last', () {
      final weeks = const ProfileStats(weeklyKm2: [1, 2]).weeklyKm2;

      expect(weeks, hasLength(ProfileStats.weeksShown));
      expect(weeks.take(ProfileStats.weeksShown - 2), everyElement(isNull));
      expect(weeks.skip(ProfileStats.weeksShown - 2), [1, 2]);
    });

    test('only the most recent weeks are kept', () {
      final data = [for (var i = 0; i < ProfileStats.weeksShown + 2; i++) i];
      final weeks = ProfileStats(
        weeklyKm2: [for (final km2 in data) km2.toDouble()],
      ).weeklyKm2;

      expect(weeks.first, 2);
      expect(weeks.last, ProfileStats.weeksShown + 1);
    });
  });
}
