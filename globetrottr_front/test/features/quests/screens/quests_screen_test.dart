import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/features/map/data/open_free_map_tile_provider.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quest_map_focus.dart';
import 'package:globetrottr_front/features/quests/screens/quest_history_screen.dart';
import 'package:globetrottr_front/features/quests/screens/quests_screen.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_swap_dialog.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../quest_test_support.dart';

class _FakeProfileService implements ProfileService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(const NetworkException());
}

final _places = [
  testQuest(1, title: 'Wawel Hill', waypoints: testWaypoints([false, false])),
  testQuest(2, title: 'Cloth Hall', waypoints: testWaypoints([false])),
];
final _route = testQuest(
  3,
  title: 'River walk',
  isRoute: true,
  waypoints: testWaypoints([false, false]),
);

void main() {
  late FakeQuestService service;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester,
    List<Quest> quests, {
    String location = '/quests',
    Locale locale = const Locale('en'),
    Size size = const Size(1170, 4000),
    AppException? failWith,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    service = FakeQuestService(quests)..failWith = failWith;
    container = ProviderContainer(
      overrides: [
        questServiceProvider.overrideWithValue(service),
        basemapTileProvider.overrideWithValue(null),
        profileServiceProvider.overrideWithValue(_FakeProfileService()),
        locationProvider.overrideWith(
          () => FakeLocationNotifier(const LatLng(50.0, 19.0)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/quests',
          builder: (_, _) => const QuestsScreen(),
          routes: [
            GoRoute(
              path: 'history',
              builder: (_, _) => const QuestHistoryScreen(),
            ),
          ],
        ),
        GoRoute(path: '/map', builder: (_, _) => const Text('map')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('QuestsScreen', () {
    testWidgets('shows an empty card and the quests grouped by type', (
      tester,
    ) async {
      await pump(tester, [..._places, _route]);

      expect(find.text('No active quest'), findsOneWidget);
      expect(find.text('PLACES'), findsOneWidget);
      expect(find.text('ROUTES'), findsOneWidget);
      expect(find.text('2 points'), findsOneWidget);
      expect(find.text('1 point'), findsOneWidget);
      expect(find.text('River walk'), findsOneWidget);
    });

    testWidgets('a failed load shows no empty card, only the error', (
      tester,
    ) async {
      await pump(tester, [], failWith: const NetworkException());

      expect(find.text('No active quest'), findsNothing);
      expect(find.byType(FormMessage), findsOneWidget);
    });

    testWidgets('shows the active quest as steps with its next point', (
      tester,
    ) async {
      await pump(tester, [
        testQuest(
          4,
          title: 'Old Town',
          isStarted: true,
          waypoints: testWaypoints([true, false, false]),
        ),
        ..._places,
      ]);

      expect(find.text('ACTIVE QUEST'), findsOneWidget);
      expect(find.text('Old Town'), findsOneWidget);
      expect(find.text('Point 2 of 3'), findsOneWidget);
      expect(find.text('Show point'), findsOneWidget);
      expect(find.text('No active quest'), findsNothing);
    });

    testWidgets('shows an active route as a bar of its length', (
      tester,
    ) async {
      await pump(tester, [
        testQuest(
          5,
          title: 'Loop',
          isRoute: true,
          isStarted: true,
          progress: 0.5,
          waypoints: testWaypoints([false, false, false], step: 0.009),
        ),
      ]);

      expect(find.text('1.0 of 2.0 km'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Show route'), findsOneWidget);
    });

    testWidgets('the show button asks the map for the active quest', (
      tester,
    ) async {
      await pump(tester, [
        testQuest(4, isStarted: true, waypoints: testWaypoints([false])),
      ]);

      await tester.tap(find.text('Show point'));
      await tester.pumpAndSettle();

      expect(find.text('map'), findsOneWidget);
      expect(container.read(questMapFocusProvider), isTrue);
    });

    testWidgets('starts a quest from its preview without asking', (
      tester,
    ) async {
      await pump(tester, _places);

      await tester.tap(find.text('Wawel Hill'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Start quest: Wawel Hill'));
      await tester.pumpAndSettle();

      expect(service.started, [1]);
      expect(find.byType(QuestSwapDialog), findsNothing);
    });

    testWidgets(
      'the last quest can be scrolled out from under the navigation',
      (
        tester,
      ) async {
        await pump(tester, [
          testQuest(
            4,
            isStarted: true,
            waypoints: testWaypoints([false, false]),
          ),
          ..._places,
          _route,
        ], size: const Size(1170, 2532));

        await tester.scrollUntilVisible(find.text('River walk'), 200);
        await tester.tap(find.text('River walk'));
        await tester.pumpAndSettle();
        final swap = find.bySemanticsLabel(
          'Swap the active quest for: River walk',
        );
        await tester.scrollUntilVisible(swap, 200);
        await tester.tap(swap);
        await tester.pumpAndSettle();

        expect(find.byType(QuestSwapDialog), findsOneWidget);
      },
    );

    testWidgets('asks before swapping the active quest', (tester) async {
      await pump(tester, [
        testQuest(
          4,
          title: 'Old Town',
          isStarted: true,
          waypoints: testWaypoints([true, false]),
        ),
        ..._places,
      ]);

      await tester.tap(find.text('Wawel Hill'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Swap the active quest for: Wawel Hill'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swap the active quest?'), findsOneWidget);
      expect(find.textContaining('(point 2 of 2)'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.started, isEmpty);

      await tester.tap(
        find.bySemanticsLabel('Swap the active quest for: Wawel Hill'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();
      expect(service.started, [1]);
    });

    testWidgets('another quest cannot be started while one is on the way', (
      tester,
    ) async {
      await pump(tester, [
        testQuest(4, isStarted: true, waypoints: testWaypoints([false])),
        ..._places,
      ]);
      service.startReply = Completer<void>();

      await tester.tap(find.text('Wawel Hill'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Swap the active quest for: Wawel Hill'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cloth Hall'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Swap the active quest for: Cloth Hall'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuestSwapDialog), findsNothing);
      expect(service.started, [1]);

      service.startReply!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('lists completed quests in the history by month', (
      tester,
    ) async {
      final now = DateTime.now();
      await pump(tester, location: '/quests/history', [
        testQuest(
          6,
          title: 'Planty',
          isRoute: true,
          isStarted: true,
          isCompleted: true,
          completedAt: DateTime(now.year, 9, 21),
        ),
        testQuest(
          7,
          title: 'Kazimierz',
          isStarted: true,
          isCompleted: true,
          completedAt: DateTime(now.year, 8, 24),
        ),
        ..._places,
      ]);

      expect(find.text('2 quests'), findsOneWidget);
      expect(find.text('SEPTEMBER'), findsOneWidget);
      expect(find.text('AUGUST'), findsOneWidget);
      expect(find.text('Routes · completed 21 Sep'), findsOneWidget);
      expect(find.text('Wawel Hill'), findsNothing);
    });

    testWidgets('speaks Polish', (tester) async {
      await pump(tester, [
        testQuest(
          4,
          isStarted: true,
          waypoints: testWaypoints([false, false, false, false, false]),
        ),
        ..._places,
      ], locale: const Locale('pl'));

      expect(find.text('Questy'), findsOneWidget);
      expect(find.text('Punkt 1 z 5'), findsOneWidget);
      expect(find.text('Pokaż punkt'), findsOneWidget);
      expect(find.text('MIEJSCA'), findsOneWidget);
      expect(find.text('2 punkty'), findsOneWidget);
    });
  });
}
