import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_sheet.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

class _FakeQuestService implements QuestService {
  _FakeQuestService(this.quests, {this.startError});

  List<Quest> quests;
  final AppException? startError;
  final List<int> startedIds = [];

  @override
  Future<List<Quest>> fetchUserQuests() async => quests;

  @override
  Future<void> startQuest(int questId) async {
    if (startError case final AppException error) throw error;
    startedIds.add(questId);
    quests = [
      for (final quest in quests)
        if (quest.id == questId) _quest(isStarted: true) else quest,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Quest _quest({
  bool isStarted = false,
  bool isCompleted = false,
  String? description = 'Visit the Main Square.',
}) => Quest(
  id: 1,
  title: 'Old Town',
  description: description,
  type: 'VISIT_POINTS',
  rewardPoints: 100,
  progress: 0.5,
  isStarted: isStarted,
  isCompleted: isCompleted,
);

Future<_FakeQuestService> _pumpSheet(
  WidgetTester tester,
  _FakeQuestService service,
) async {
  final container = ProviderContainer(
    overrides: [questServiceProvider.overrideWithValue(service)],
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
        home: NeumorphicTheme(
          child: const Scaffold(body: QuestDetailsSheet(questId: 1)),
        ),
      ),
    ),
  );
  return service;
}

void main() {
  testWidgets('shows title, description and reward', (tester) async {
    await _pumpSheet(tester, _FakeQuestService([_quest()]));

    expect(find.text('Old Town'), findsOneWidget);
    expect(find.text('Visit the Main Square.'), findsOneWidget);
    expect(find.text('100 XP'), findsOneWidget);
  });

  testWidgets('shows a placeholder when the description is missing', (
    tester,
  ) async {
    await _pumpSheet(tester, _FakeQuestService([_quest(description: null)]));

    expect(find.text('No description yet.'), findsOneWidget);
  });

  testWidgets('starts the quest and switches to progress', (tester) async {
    final service = await _pumpSheet(tester, _FakeQuestService([_quest()]));

    await tester.tap(find.text('Start Quest'));
    await tester.pumpAndSettle();

    expect(service.startedIds, [1]);
    expect(find.text('Start Quest'), findsNothing);
    expect(find.text('50% progress'), findsOneWidget);
  });

  testWidgets('shows the error message when starting fails', (tester) async {
    await _pumpSheet(
      tester,
      _FakeQuestService([_quest()], startError: const UnknownException()),
    );

    await tester.tap(find.text('Start Quest'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('shows completed state without a start button', (tester) async {
    await _pumpSheet(
      tester,
      _FakeQuestService([_quest(isStarted: true, isCompleted: true)]),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Start Quest'), findsNothing);
  });
}
