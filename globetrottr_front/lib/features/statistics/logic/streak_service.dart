import 'dart:math' as math;

import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';

class StreakService {
  const StreakService();

  static const double minDistanceForRecordingStreak = 100.0;
  static const double minAreaForRecordingStreak = 1.0;

  UserStreakStats recordAppOpen(
    UserStreakStats current, {
    DateTime? now,
  }) {
    final currentMoment = now ?? DateTime.now();
    final todayStr = _formatDate(currentMoment);

    if (current.lastOpenDate == todayStr) {
      return current;
    }

    final newStreak = _nextStreak(
      current.lastOpenDate,
      currentMoment,
      current.currentOpenStreak,
    );
    return current.copyWith(
      currentOpenStreak: newStreak,
      maxOpenStreak: math.max(current.maxOpenStreak, newStreak),
      lastOpenDate: todayStr,
    );
  }

  UserStreakStats recordTripCompleted(
    UserStreakStats current, {
    required double distanceM,
    required double newAreaM2,
    DateTime? now,
  }) {
    if (distanceM < minDistanceForRecordingStreak &&
        newAreaM2 < minAreaForRecordingStreak) {
      return current;
    }

    final currentMoment = now ?? DateTime.now();
    final todayStr = _formatDate(currentMoment);

    if (current.lastRecordingDate == todayStr) {
      return current;
    }

    final newStreak = _nextStreak(
      current.lastRecordingDate,
      currentMoment,
      current.currentRecordingStreak,
    );

    return current.copyWith(
      currentRecordingStreak: newStreak,
      maxRecordingStreak: math.max(current.maxRecordingStreak, newStreak),
      lastRecordingDate: todayStr,
    );
  }

  int _nextStreak(String? lastDateStr, DateTime now, int currentStreak) {
    if (lastDateStr == null) return 1;

    try {
      final last = DateTime.parse(lastDateStr);
      final todayMidnight = DateTime.utc(now.year, now.month, now.day);
      final lastMidnight = DateTime.utc(last.year, last.month, last.day);
      final diff = todayMidnight.difference(lastMidnight).inDays;

      if (diff == 1) {
        return currentStreak + 1;
      } else if (diff > 1) {
        return 1;
      }
      return currentStreak;
    } catch (_) {
      return 1;
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
