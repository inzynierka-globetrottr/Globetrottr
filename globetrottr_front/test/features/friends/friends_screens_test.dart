import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/unfold_transition.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/data/invite_status.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';
import 'package:globetrottr_front/features/friends/provider/weekly_ranking.dart';
import 'package:globetrottr_front/features/friends/screens/add_friend_screen.dart';
import 'package:globetrottr_front/features/friends/screens/friends_screen.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/weekly_person.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

FriendshipResponse _person(String name, {bool incoming = false}) =>
    FriendshipResponse(
      username: name,
      status: InviteStatus.pending,
      isIncomingRequest: incoming,
    );

class _FakeFriendsService implements FriendsService {
  List<FriendshipResponse> friends = [];
  List<FriendshipResponse> received = [];
  List<FriendshipResponse> sent = [];
  final List<String> invited = [];
  final List<String> accepted = [];
  AppException? failWith;
  AppException? loadFailWith;

  /// Holds the friends back until completed, as a slow backend would.
  Completer<void>? arrival;

  @override
  Future<List<FriendshipResponse>> getFriends() async {
    await arrival?.future;
    final error = loadFailWith;
    if (error != null) throw error;
    return friends;
  }

  @override
  Future<List<FriendshipResponse>> getReceivedInvites() async => received;

  @override
  Future<List<FriendshipResponse>> getSentInvites() async => sent;

  @override
  Future<void> sendInvite(String username) async {
    final error = failWith;
    if (error != null) throw error;
    invited.add(username);
  }

  @override
  Future<void> acceptInvite(String username) async => accepted.add(username);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileService implements ProfileService {
  @override
  Future<String?> getAvatarUrl(String username) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(const NetworkException());
}

void main() {
  late _FakeFriendsService friends;

  setUp(() => friends = _FakeFriendsService());

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    List<WeeklyEntry>? weekly,
    Size size = const Size(1170, 2532),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendsServiceProvider.overrideWithValue(friends),
          profileServiceProvider.overrideWithValue(_FakeProfileService()),
          if (weekly != null) weeklyRankingProvider.overrideWithValue(weekly),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('received invites open from one row and can be accepted', (
    tester,
  ) async {
    friends.received = [
      _person('rafalwrona', incoming: true),
      _person('discoadamus', incoming: true),
    ];
    await pump(tester, const FriendsScreen());

    expect(find.text('2 invites'), findsOneWidget);
    expect(find.text('rafalwrona, discoadamus'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Accept the invite from rafalwrona'),
      findsNothing,
    );

    await tester.tap(find.text('2 invites'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel('Accept the invite from rafalwrona'),
    );
    await tester.pumpAndSettle();

    expect(friends.accepted, ['rafalwrona']);
    expect(find.text('1 invite'), findsOneWidget);
  });

  testWidgets('friends show neutral values until the data exists', (
    tester,
  ) async {
    friends.friends = [_person('marekgarek')];
    await pump(tester, const FriendsScreen());

    expect(find.text('Your friends · 1'.toUpperCase()), findsOneWidget);
    expect(find.text('marekgarek'), findsOneWidget);
    expect(find.text('— km²'), findsNWidgets(2));
    expect(find.text('–'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('no empty card shows while the friends are on their way', (
    tester,
  ) async {
    friends
      ..friends = [_person('ola')]
      ..arrival = Completer<void>();
    await pump(tester, const FriendsScreen());

    expect(find.text('No friends yet'), findsNothing);

    friends.arrival!.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.standard.medium ~/ 2);

    final list = find
        .ancestor(of: find.text('ola'), matching: find.byType(UnfoldTransition))
        .last;
    expect(
      tester.widget<UnfoldTransition>(list).listenable,
      isA<Animation<double>>(),
    );
    expect(
      (tester.widget<UnfoldTransition>(list).listenable as Animation<double>)
          .value,
      1,
    );
    expect(find.text('No friends yet'), findsNothing);
  });

  testWidgets('a failed load shows no empty card, only the error', (
    tester,
  ) async {
    friends.loadFailWith = const NetworkException();
    await pump(tester, const FriendsScreen());

    expect(find.text('No friends yet'), findsNothing);
    expect(find.byType(FormMessage), findsOneWidget);
  });

  testWidgets('without friends one card replaces the strip and the list', (
    tester,
  ) async {
    await pump(tester, const FriendsScreen());

    expect(find.byType(WeeklyPerson), findsNothing);
    expect(find.text('This week'.toUpperCase()), findsNothing);
    expect(find.textContaining('Your friends'), findsNothing);
    expect(find.text('No friends yet'), findsOneWidget);
    expect(find.text('Add a friend'), findsOneWidget);
  });

  testWidgets('the empty card sends the user to adding a friend', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const FriendsScreen()),
        GoRoute(
          path: '/friends/add',
          builder: (_, _) => const Text('add-screen'),
        ),
      ],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendsServiceProvider.overrideWithValue(friends),
          profileServiceProvider.overrideWithValue(_FakeProfileService()),
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

    await tester.tap(find.text('Add a friend').last);
    await tester.pumpAndSettle();

    expect(find.text('add-screen'), findsOneWidget);
  });

  testWidgets('a sent invite appears under the form', (tester) async {
    await pump(tester, const AddFriendScreen());

    await tester.enterText(find.byType(TextField), 'fagata');
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    expect(friends.invited, ['fagata']);
    expect(find.text('SENT'), findsOneWidget);
    expect(find.text('fagata'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('a failed invite says why', (tester) async {
    friends.failWith = const ValidationException('Receiver not found', 400);
    await pump(tester, const AddFriendScreen());

    await tester.enterText(find.byType(TextField), 'nikt');
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    expect(find.text('There is no user with this nickname.'), findsOneWidget);
  });

  testWidgets('more than four people scroll, the next one peeks in', (
    tester,
  ) async {
    final weekly = [
      for (var i = 0; i < 6; i++)
        WeeklyEntry(username: 'p$i', weeklyKm2: 1.0 - i / 10, ringFill: 1),
    ];
    friends.friends = [_person('p1')];
    await pump(tester, const FriendsScreen(), weekly: weekly);

    final screenWidth = tester.view.physicalSize.width / 3;
    final fifth = tester.getRect(find.byType(WeeklyPerson).at(4));
    expect(fifth.left, lessThan(screenWidth));
    expect(fifth.right, greaterThan(screenWidth));
  });

  for (final people in [3, 6]) {
    testWidgets('$people people fit a narrow screen without overlapping', (
      tester,
    ) async {
      final weekly = [
        for (var i = 0; i < people; i++)
          WeeklyEntry(username: 'p$i', weeklyKm2: 1.0 - i / 10, ringFill: 1),
      ];
      friends.friends = [_person('p1')];
      await pump(
        tester,
        const FriendsScreen(),
        weekly: weekly,
        size: const Size(960, 2079),
      );

      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byType(WeeklyPerson).at(0));
      final second = tester.getRect(find.byType(WeeklyPerson).at(1));
      expect(second.left, greaterThanOrEqualTo(first.right));
    });
  }
}
