import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_accordion_section.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_sheet.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

const _quest = Quest(
  id: 3,
  title: 'Hidden courtyard',
  description: 'Find the courtyard behind the gate.',
  type: 'VISIT_POINTS',
  rewardPoints: 50,
  progress: 0,
  isStarted: false,
  isCompleted: false,
);

class _FakeQuestService implements QuestService {
  @override
  Future<List<Quest>> fetchUserQuests() async => [_quest];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('opens quest details when a card without location is tapped', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [questServiceProvider.overrideWithValue(_FakeQuestService())],
    );
    addTearDown(container.dispose);
    await container.read(questsProvider.notifier).loadQuests();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuestAccordionSection(
              title: 'Available',
              zone: QuestZone.unstarted,
              entries: const [QuestBoardEntry(quest: _quest)],
              icon: Icons.explore_outlined,
              isExpanded: true,
              onToggle: () {},
              onStartQuest: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hidden courtyard'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestDetailsSheet), findsOneWidget);
    expect(find.text('Find the courtyard behind the gate.'), findsOneWidget);
  });

  testWidgets('shows the formatted distance of every quest in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuestAccordionSection(
            title: 'Available',
            zone: QuestZone.unstarted,
            entries: const [
              QuestBoardEntry(quest: _quest, distanceMeters: 354),
              QuestBoardEntry(quest: _quest, distanceMeters: 1240),
            ],
            icon: Icons.explore_outlined,
            isExpanded: true,
            onToggle: () {},
            onStartQuest: (_) {},
          ),
        ),
      ),
    );

    final near = tester.getTopLeft(find.text('350 m'));
    final far = tester.getTopLeft(find.text('1,2 km'));
    expect(near.dy, lessThan(far.dy));
  });
}
