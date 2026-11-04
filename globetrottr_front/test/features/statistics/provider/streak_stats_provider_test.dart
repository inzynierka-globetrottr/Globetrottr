import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/statistics/data/statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

class _StreakOnlyStatistics extends Fake implements StatisticsStorage {
  UserStreakStats saved = UserStreakStats.empty;

  @override
  Future<UserStreakStats> loadStreakStats() async => saved;

  @override
  Future<void> saveStreakStats(UserStreakStats stats) async => saved = stats;
}

void main() {
  late _StreakOnlyStatistics storage;
  late ProviderContainer container;

  setUp(() {
    storage = _StreakOnlyStatistics();
    container = ProviderContainer(
      overrides: [statisticsStorageProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() => container.dispose());

  test('opens on consecutive days make a two-day streak', () async {
    final notifier = container.read(streakStatsProvider.notifier);

    await notifier.recordAppOpen(now: DateTime(2026, 11, 3, 9));
    await notifier.recordAppOpen(now: DateTime(2026, 11, 4, 9));

    expect(storage.saved.currentOpenStreak, 2);
    expect(storage.saved.lastOpenDate, '2026-11-04');
  });

  test('a second open on the same day does not refresh statistics', () async {
    final notifier = container.read(streakStatsProvider.notifier);

    await notifier.recordAppOpen(now: DateTime(2026, 11, 3, 9));
    final afterFirst = container.read(statisticsRevisionProvider);
    await notifier.recordAppOpen(now: DateTime(2026, 11, 3, 21));

    expect(afterFirst, 1);
    expect(container.read(statisticsRevisionProvider), 1);
  });
}
