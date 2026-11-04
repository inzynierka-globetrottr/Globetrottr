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

    group('recordRecordingDay', () {
      test('the first recording day starts a streak', () {
        final updated = service.recordRecordingDay(
          UserStreakStats.empty,
          now: DateTime(2026, 11, 3, 11),
        );

        expect(updated.currentRecordingStreak, 1);
        expect(updated.maxRecordingStreak, 1);
        expect(updated.lastRecordingDate, '2026-11-03');
      });

      test('a second recording on the same day keeps the streak', () {
        final first = service.recordRecordingDay(
          UserStreakStats.empty,
          now: DateTime(2026, 11, 3, 11),
        );

        final second = service.recordRecordingDay(
          first,
          now: DateTime(2026, 11, 3, 20),
        );

        expect(second.currentRecordingStreak, 1);
      });

      test('a recording on the next day extends the streak', () {
        final first = service.recordRecordingDay(
          UserStreakStats.empty,
          now: DateTime(2026, 11, 3, 23, 50),
        );

        final second = service.recordRecordingDay(
          first,
          now: DateTime(2026, 11, 4, 0, 20),
        );

        expect(second.currentRecordingStreak, 2);
        expect(second.maxRecordingStreak, 2);
      });

      test('a skipped day restarts the streak', () {
        const initial = UserStreakStats(
          currentOpenStreak: 5,
          maxOpenStreak: 5,
          lastOpenDate: '2026-11-03',
          currentRecordingStreak: 7,
          maxRecordingStreak: 12,
          lastRecordingDate: '2026-10-30',
        );

        final updated = service.recordRecordingDay(
          initial,
          now: DateTime(2026, 11, 3, 11),
        );

        expect(updated.currentRecordingStreak, 1);
        expect(updated.maxRecordingStreak, 12);
        expect(updated.lastRecordingDate, '2026-11-03');
      });
    });

    group('effectiveStreaks', () {
      test(
        'effectiveRecordingStreak returns current when recorded today or yesterday',
        () {
          final today = DateTime(2026, 11, 3);
          final statsToday = UserStreakStats.empty.copyWith(
            currentRecordingStreak: 5,
            lastRecordingDate: '2026-11-03',
          );
          expect(service.effectiveRecordingStreak(statsToday, today), 5);

          final statsYesterday = UserStreakStats.empty.copyWith(
            currentRecordingStreak: 5,
            lastRecordingDate: '2026-11-02',
          );
          expect(service.effectiveRecordingStreak(statsYesterday, today), 5);
        },
      );

      test('effectiveRecordingStreak returns 0 when older than yesterday', () {
        final today = DateTime(2026, 11, 3);
        final statsOld = UserStreakStats.empty.copyWith(
          currentRecordingStreak: 10,
          lastRecordingDate: '2026-10-25',
        );
        expect(service.effectiveRecordingStreak(statsOld, today), 0);
      });

      test('effectiveOpenStreak returns 0 when older than yesterday', () {
        final today = DateTime(2026, 11, 3);
        final statsOld = UserStreakStats.empty.copyWith(
          currentOpenStreak: 14,
          lastOpenDate: '2026-10-20',
        );
        expect(service.effectiveOpenStreak(statsOld, today), 0);
      });
    });
  });
}
