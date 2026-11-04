import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/router/friend_routes.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/fog/data/fog_service.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';
import 'package:globetrottr_front/features/friends/screens/friend_map_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friend_profile_screen.dart';
import 'package:globetrottr_front/features/map/data/open_free_map_tile_provider.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../quests/quest_test_support.dart';

class _FakeFogService extends Fake implements FogService {
  _FakeFogService({this.fails = false});

  final bool fails;

  @override
  Future<List<List<LatLng>>> getFriendFog(String friendUsername) async {
    if (fails) throw const NetworkException();
    return [
      const [LatLng(50.06, 19.93), LatLng(50.07, 19.95), LatLng(50.05, 19.96)],
    ];
  }
}

class _FakeFriendsService extends Fake implements FriendsService {
  _FakeFriendsService([this.usernames = const ['marekgarek']]);

  final List<String> usernames;

  @override
  Future<List<FriendshipResponse>> getFriends() async => [
    for (final username in usernames)
      FriendshipResponse(
        username: username,
        status: null,
        isIncomingRequest: false,
      ),
  ];

  @override
  Future<List<FriendshipResponse>> getReceivedInvites() async => const [];

  @override
  Future<List<FriendshipResponse>> getSentInvites() async => const [];
}

class _FakeProfileService implements ProfileService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(const NetworkException());
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? location,
    List<String> friends = const ['marekgarek'],
    bool fogFails = false,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location ?? FriendRoutes.profile('marekgarek'),
      routes: [friendsRoute],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fogServiceProvider.overrideWithValue(
            _FakeFogService(fails: fogFails),
          ),
          friendsServiceProvider.overrideWithValue(
            _FakeFriendsService(friends),
          ),
          profileServiceProvider.overrideWithValue(_FakeProfileService()),
          basemapTileProvider.overrideWithValue(null),
          questServiceProvider.overrideWithValue(FakeQuestService(const [])),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 4)),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openComparison(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Comparison'));
    await tester.pumpAndSettle();
  }

  testWidgets('a friend in the list opens their profile', (tester) async {
    await pump(tester, location: FriendRoutes.list);

    await tester.tap(find.bySemanticsLabel('Open marekgarek'));
    await tester.pumpAndSettle();

    expect(find.byType(FriendProfileScreen), findsOneWidget);
    expect(find.text('New area per week'), findsOneWidget);
    expect(find.text('discovered area'), findsOneWidget);
    expect(find.text('Duel'), findsNothing);
  });

  testWidgets('the comparison shows neutral values until the data exists', (
    tester,
  ) async {
    await pump(tester);
    await openComparison(tester);

    expect(find.text('marekgarek'), findsWidgets);
    expect(find.text('Only you'), findsOneWidget);
    expect(find.text('Shared'), findsOneWidget);
    expect(find.text('Only marekgarek'), findsOneWidget);
    expect(find.text('DISCOVERED'), findsOneWidget);
    expect(find.text('— km²'), findsNWidgets(2));
    expect(find.bySemanticsLabel('better result'), findsNothing);
  });

  testWidgets('the better value of a duel gets a tick', (tester) async {
    await pump(
      tester,
      overrides: [
        friendComparisonProvider('marekgarek').overrideWithValue(
          const FriendComparison(
            quests: Duel(me: 14, friend: 9),
            places: [
              PlaceComparison(
                name: 'Skawina',
                myShare: 0.01,
                friendShare: 0,
              ),
            ],
          ),
        ),
      ],
    );
    await openComparison(tester);

    expect(find.text('14'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.bySemanticsLabel('better result'), findsOneWidget);
    expect(find.text('Skawina'), findsOneWidget);
    expect(find.text('1.0%'), findsOneWidget);
  });

  testWidgets('the tabs switch between the comparison and the profile', (
    tester,
  ) async {
    await pump(tester);
    await openComparison(tester);

    expect(find.text('Duel'), findsOneWidget);
    expect(find.text('New area per week'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('New area per week'), findsOneWidget);
    expect(find.text('Duel'), findsNothing);
  });

  testWidgets('the profile map opens the friend fog on their area', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Open the map full screen'));
    await tester.pumpAndSettle();

    expect(find.byType(FriendMapScreen), findsOneWidget);
    expect(find.text('— km² discovered'), findsOneWidget);
    expect(find.text("marekgarek's area"), findsOneWidget);
    expect(find.text('Together with me'), findsOneWidget);
    expect(find.text('Only you'), findsNothing);

    await tester.tap(find.text('Together with me'));
    await tester.pumpAndSettle();

    expect(find.text('Only you'), findsOneWidget);
    expect(find.text('Only marekgarek'), findsOneWidget);
  });

  testWidgets('the comparison map opens the fog together with mine', (
    tester,
  ) async {
    await pump(tester);
    await openComparison(tester);

    await tester.tap(find.bySemanticsLabel('Open the map full screen'));
    await tester.pumpAndSettle();

    expect(find.byType(FriendMapScreen), findsOneWidget);
    expect(find.text('Only you'), findsOneWidget);
  });

  for (final username in ['add', 'a/b?c#d', '100%']) {
    testWidgets('a friend named "$username" opens their own profile and map', (
      tester,
    ) async {
      await pump(tester, location: FriendRoutes.list, friends: [username]);

      await tester.tap(find.bySemanticsLabel('Open $username'));
      await tester.pumpAndSettle();

      final profile = tester.widget<FriendProfileScreen>(
        find.byType(FriendProfileScreen),
      );
      expect(profile.username, username);

      await tester.tap(find.bySemanticsLabel('Open the map full screen'));
      await tester.pumpAndSettle();

      final map = tester.widget<FriendMapScreen>(find.byType(FriendMapScreen));
      expect(map.friendUsername, username);
    });
  }

  testWidgets('a failed fog request says so instead of an empty map', (
    tester,
  ) async {
    await pump(tester, fogFails: true);

    expect(find.text("Couldn't load the map"), findsOneWidget);
  });
}
