import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/statistics/data/user_streak_stats.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/app_open_recorder.dart';

class _CountingStreaks extends StreakStatsNotifier {
  int opens = 0;

  @override
  Future<UserStreakStats> build() async => UserStreakStats.empty;

  @override
  Future<void> recordAppOpen({DateTime? now}) async => opens++;
}

void main() {
  testWidgets('records an app open at start and on every resume', (
    tester,
  ) async {
    final streaks = _CountingStreaks();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [streakStatsProvider.overrideWith(() => streaks)],
        child: const AppOpenRecorder(child: SizedBox()),
      ),
    );
    await tester.pump();
    expect(streaks.opens, 1);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(streaks.opens, 2);
  });
}
