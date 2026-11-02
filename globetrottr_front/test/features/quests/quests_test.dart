import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

Quest _quest({double progress = 0}) => Quest(
  id: 1,
  title: 'Old Town',
  type: 'AREA',
  rewardPoints: 100,
  progress: progress,
  isStarted: true,
  isCompleted: false,
);

class _FakeQuestService implements QuestService {
  int fetches = 0;

  @override
  Future<List<Quest>> fetchUserQuests() async {
    fetches++;
    return [_quest()];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('the map loads the quests only the first time', () async {
    final service = _FakeQuestService();
    final container = ProviderContainer(
      overrides: [questServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(questsProvider.notifier);

    await notifier.loadQuestsOnce();
    await notifier.loadQuestsOnce();

    expect(service.fetches, 1);
    expect(container.read(questsProvider).quests, hasLength(1));
  });

  testWidgets('the card rounds the progress like the map card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuestCard(
            quest: _quest(progress: 0.996),
            zone: QuestZone.inProgress,
          ),
        ),
      ),
    );

    expect(find.text('100% progress'), findsOneWidget);
  });
}
