import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/streak_service.dart';

void main() {
  group('StreakService', () {
    const service = StreakService();

    group('recordAppOpen', () {
      test('initializes streak on first app open', () {
        const initial = UserStreakStats.empty;
        final now = DateTime(2026, 11, 3, 10);

        final updated = service.recordAppOpen(initial, now: now);

        expect(updated.currentOpenStreak, 1);
        expect(updated.maxOpenStreak, 1);
        expect(updated.lastOpenDate, '2026-11-03');
      });

      test('does not increment on same-day reopen', () {
        const initial = UserStreakStats(
          currentOpenStreak: 4,
          maxOpenStreak: 7,
          lastOpenDate: '2026-11-03',
          currentRecordingStreak: 2,
          maxRecordingStreak: 5,
          lastRecordingDate: null,
        );
        final laterToday = DateTime(2026, 11, 3, 18, 30);

        final updated = service.recordAppOpen(initial, now: laterToday);

        expect(updated.currentOpenStreak, 4);
        expect(updated.maxOpenStreak, 7);
        expect(updated.lastOpenDate, '2026-11-03');
      });

      test('increments streak on consecutive day', () {
        const initial = UserStreakStats(
          currentOpenStreak: 4,
          maxOpenStreak: 4,
          lastOpenDate: '2026-11-02',
          currentRecordingStreak: 0,
          maxRecordingStreak: 0,
          lastRecordingDate: null,
        );
        final nextDay = DateTime(2026, 11, 3, 9, 15);

        final updated = service.recordAppOpen(initial, now: nextDay);

        expect(updated.currentOpenStreak, 5);
        expect(updated.maxOpenStreak, 5);
        expect(updated.lastOpenDate, '2026-11-03');
      });

      test('resets streak to 1 when a day is skipped', () {
        const initial = UserStreakStats(
          currentOpenStreak: 6,
          maxOpenStreak: 10,
          lastOpenDate: '2026-10-31',
          currentRecordingStreak: 0,
          maxRecordingStreak: 0,
          lastRecordingDate: null,
        );
        final afterGap = DateTime(2026, 11, 3, 9, 15);

        final updated = service.recordAppOpen(initial, now: afterGap);

        expect(updated.currentOpenStreak, 1);
        expect(updated.maxOpenStreak, 10);
        expect(updated.lastOpenDate, '2026-11-03');
      });
    });

    group('recordTripCompleted', () {
      test(
        'increments recording streak when trip meets distance threshold',
        () {
          const initial = UserStreakStats.empty;
          final now = DateTime(2026, 11, 3, 11);

          final updated = service.recordTripCompleted(
            initial,
            now: now,
            distanceM: 250,
            newAreaM2: 0,
          );

          expect(updated.currentRecordingStreak, 1);
          expect(updated.maxRecordingStreak, 1);
          expect(updated.lastRecordingDate, '2026-11-03');
        },
      );

      test(
        'does not increment recording streak if trip is trivial (<100m and 0 new area)',
        () {
          const initial = UserStreakStats.empty;
          final now = DateTime(2026, 11, 3, 11);

          final updated = service.recordTripCompleted(
            initial,
            now: now,
            distanceM: 40,
            newAreaM2: 0,
          );

          expect(updated.currentRecordingStreak, 0);
          expect(updated.lastRecordingDate, isNull);
        },
      );

      test(
        'increments recording streak if distance is short but new area was discovered',
        () {
          const initial = UserStreakStats.empty;
          final now = DateTime(2026, 11, 3, 11);

          final updated = service.recordTripCompleted(
            initial,
            now: now,
            distanceM: 50,
            newAreaM2: 1500,
          );

          expect(updated.currentRecordingStreak, 1);
          expect(updated.lastRecordingDate, '2026-11-03');
        },
      );

      test('resets recording streak when more than one day is skipped', () {
        const initial = UserStreakStats(
          currentOpenStreak: 5,
          maxOpenStreak: 5,
          lastOpenDate: '2026-11-03',
          currentRecordingStreak: 7,
          maxRecordingStreak: 12,
          lastRecordingDate: '2026-10-30',
        );
        final now = DateTime(2026, 11, 3, 11);

        final updated = service.recordTripCompleted(
          initial,
          now: now,
          distanceM: 500,
          newAreaM2: 200,
        );

        expect(updated.currentRecordingStreak, 1);
        expect(updated.maxRecordingStreak, 12);
        expect(updated.lastRecordingDate, '2026-11-03');
      });
    });
  });
}
