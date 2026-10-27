import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations tests', () {
    test('English localization loads all expected core strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.appTitle, 'Globetrottr');
      expect(l10n.appLogo, 'globetrottr');
      expect(l10n.authSignIn, 'Sign in');
      expect(l10n.authSignUp, 'Sign up');
      expect(l10n.authUsernamePlaceholder, 'Username');
      expect(l10n.profileDefaultUsername, 'Traveler');
      expect(l10n.profileLogOut, 'Log Out');
      expect(l10n.friendsTitle, 'Friends');
      expect(l10n.friendsYourFriendsHeader(5), 'YOUR FRIENDS (5)');
      expect(l10n.friendsInviteSent('alice'), 'Invite sent to alice!');
      expect(l10n.questsBoardTitle, 'Quest Board');
      expect(l10n.questsAvailableSection(3), 'Available Quests (3)');
      expect(l10n.questsProgressPercent(42), '42% progress');
      expect(l10n.questsRewardXp(150), '150 XP');
      expect(l10n.settingsTitle, 'Settings');
      expect(l10n.settingsLanguage, 'Language');
      expect(l10n.settingsEnglish, 'English');
      expect(l10n.settingsPolish, 'Polski');
      expect(
        l10n.errorGoogleAuthFailed,
        'Google authentication failed.',
      );
      expect(l10n.errorServer(500), 'Server error (500)');
    });

    test('Polish localization loads all expected core strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('pl'));

      expect(l10n.appTitle, 'Globetrottr');
      expect(l10n.appLogo, 'globetrottr');
      expect(l10n.authSignIn, 'Zaloguj się');
      expect(l10n.authSignUp, 'Zarejestruj się');
      expect(l10n.authUsernamePlaceholder, 'Nazwa użytkownika');
      expect(l10n.profileDefaultUsername, 'Podróżnik');
      expect(l10n.profileLogOut, 'Wyloguj się');
      expect(l10n.friendsTitle, 'Znajomi');
      expect(l10n.friendsYourFriendsHeader(5), 'TWOI ZNAJOMI (5)');
      expect(l10n.friendsInviteSent('alice'), 'Wysłano zaproszenie do alice!');
      expect(l10n.questsBoardTitle, 'Tablica zadań');
      expect(l10n.questsAvailableSection(3), 'Dostępne zadania (3)');
      expect(l10n.questsProgressPercent(42), 'Postęp: 42%');
      expect(l10n.questsRewardXp(150), '150 XP');
      expect(l10n.settingsTitle, 'Ustawienia');
      expect(l10n.settingsLanguage, 'Język');
      expect(l10n.settingsEnglish, 'English');
      expect(l10n.settingsPolish, 'Polski');
      expect(
        l10n.errorGoogleAuthFailed,
        'Logowanie przez Google nie powiodło się.',
      );
      expect(l10n.errorServer(500), 'Błąd serwera (500)');
    });

    test('Dart error translations map strings properly', () {
      expect(
        translateErrorDart('Session expired. Please log in again.'),
        'Session expired. Please log in again.',
      );
      expect(
        translateErrorDart(
          'Session expired. Please log in again.',
          locale: 'pl',
        ),
        'Sesja wygasła. Zaloguj się ponownie.',
      );
      expect(
        translateErrorDart(
          'Network error. Please check your connection.',
          locale: 'pl',
        ),
        'Błąd sieci. Sprawdź swoje połączenie.',
      );
      expect(
        translateErrorDart(
          'Google authentication failed.',
          locale: 'pl',
        ),
        'Logowanie przez Google nie powiodło się.',
      );
      expect(
        translateErrorDart(
          'Server error (502)',
          locale: 'pl',
        ),
        'Błąd serwera (502)',
      );
      expect(
        translateErrorDart(
          'Recording your route in the background...',
          locale: 'pl',
        ),
        'Nagrywanie trasy w tle...',
      );
      expect(
        translateErrorDart('Unknown error string', locale: 'pl'),
        'Unknown error string',
      );
    });

    test(
      'loadPersistedLocale returns null when storage is uninitialized',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final locale = await loadPersistedLocale();
        expect(locale, isNull);
      },
    );
  });
}
