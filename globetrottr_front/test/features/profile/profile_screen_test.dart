import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/features/profile/data/user_profile_response.dart';
import 'package:globetrottr_front/features/profile/screens/profile_screen.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/avatar_picker.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

import '../quests/quest_test_support.dart';

class _FakeProfileService implements ProfileService {
  final uploaded = <String>[];
  Completer<String>? upload;

  @override
  Future<String> uploadAvatar(String filePath) {
    uploaded.add(filePath);
    return (upload = Completer<String>()).future;
  }

  @override
  Future<UserProfileResponse> getMyProfile() async => const UserProfileResponse(
    username: 'odkrywca',
    avatarUrl: null,
    bio: null,
    totalPoints: 2340,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(const NetworkException());
}

void main() {
  late _FakeProfileService profiles;

  setUp(() => profiles = _FakeProfileService());

  Future<void> pump(WidgetTester tester, {String? pickedImage}) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(profiles),
          avatarImagePickerProvider.overrideWithValue(
            () async => pickedImage,
          ),
          questServiceProvider.overrideWithValue(
            FakeQuestService([
              testQuest(1, isCompleted: true),
              testQuest(2, isCompleted: true),
              testQuest(3),
            ]),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 4)),
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
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the profile with neutral values for missing data', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('odkrywca'), findsOneWidget);
    expect(find.text('Routes'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('— km²'), findsOneWidget);
    expect(find.text('New area per week'), findsOneWidget);
    for (final label in ['14', 'Sep', '28', 'Oct', '26', 'now']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('— km'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('—%'), findsOneWidget);
  });

  testWidgets('tapping the name unfolds the level details', (tester) async {
    await pump(tester);
    expect(find.text('2,340 XP'), findsNothing);

    await tester.tap(find.text('odkrywca'));
    await tester.pumpAndSettle();

    expect(find.text('Level –'), findsOneWidget);
    expect(find.text('2,340 XP'), findsOneWidget);

    await tester.tap(find.text('odkrywca'));
    await tester.pumpAndSettle();

    expect(find.text('2,340 XP'), findsNothing);
  });

  testWidgets('the corner button opens the settings with the logout', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Change profile picture'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  Future<void> changePicture(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change profile picture'));
    await tester.pump();
  }

  testWidgets('a picked picture is uploaded while the avatar shows it', (
    tester,
  ) async {
    await pump(tester, pickedImage: 'photos/me.jpg');

    await changePicture(tester);
    // The dialog closes; the spinner keeps animating, so nothing settles.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Language'), findsNothing);
    expect(profiles.uploaded, ['photos/me.jpg']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    profiles.upload!.complete('https://example.com/me.jpg');
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == 'https://example.com/me.jpg',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed upload says why', (tester) async {
    await pump(tester, pickedImage: 'photos/me.jpg');

    await changePicture(tester);
    await tester.pump();
    profiles.upload!.completeError(
      const ServerException('Server error (500)', 500),
    );
    await tester.pumpAndSettle();

    expect(find.text('Server error (500)'), findsOneWidget);
  });

  testWidgets('cancelling the picker uploads nothing', (tester) async {
    await pump(tester);

    await changePicture(tester);
    await tester.pumpAndSettle();

    expect(profiles.uploaded, isEmpty);
  });
}
