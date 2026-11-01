import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

const _quest = Quest(
  id: 1,
  title: 'Old town walk',
  type: 'VISIT_POINTS',
  rewardPoints: 100,
  progress: 0.4,
  isStarted: true,
  isCompleted: false,
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('QuestCard', () {
    for (final zone in QuestZone.values) {
      testWidgets('shows the distance on a ${zone.name} card', (tester) async {
        await tester.pumpWidget(
          _app(QuestCard(quest: _quest, zone: zone, distanceLabel: '350 m')),
        );

        expect(find.text('350 m'), findsOneWidget);
        expect(find.byIcon(Icons.near_me_outlined), findsOneWidget);
      });
    }

    testWidgets('shows the distance next to the progress', (tester) async {
      await tester.pumpWidget(
        _app(
          const QuestCard(
            quest: _quest,
            zone: QuestZone.inProgress,
            distanceLabel: '1.2 km',
          ),
        ),
      );

      expect(find.text('40% progress'), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
    });

    testWidgets('hides the distance when it is unknown', (tester) async {
      await tester.pumpWidget(
        _app(const QuestCard(quest: _quest, zone: QuestZone.unstarted)),
      );

      expect(find.byIcon(Icons.near_me_outlined), findsNothing);
    });
  });
}
