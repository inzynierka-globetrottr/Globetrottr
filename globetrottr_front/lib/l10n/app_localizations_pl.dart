// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Globetrottr';

  @override
  String get appLogo => 'globetrottr';

  @override
  String get authSignIn => 'Zaloguj się';

  @override
  String get authSignUp => 'Zarejestruj się';

  @override
  String get authUsernamePlaceholder => 'Nazwa użytkownika';

  @override
  String get authEmailPlaceholder => 'Email';

  @override
  String get authPasswordPlaceholder => 'Hasło';

  @override
  String get authLoading => 'Ładowanie...';

  @override
  String get authOrContinueWith => 'LUB KONTYNUUJ PRZEZ';

  @override
  String get authGoogleAccount => 'Konto Google';

  @override
  String get profileDefaultUsername => 'Podróżnik';

  @override
  String get profileBioPlaceholder => 'Opowiedz innym o swoich podróżach...';

  @override
  String get profileCancel => 'Anuluj';

  @override
  String get profileSave => 'Zapisz';

  @override
  String get profileTotalPoints => 'Punkty łączne';

  @override
  String get profileStatistics => 'Statystyki';

  @override
  String get profileAchievements => 'Osiągnięcia';

  @override
  String get profileSettings => 'Ustawienia';

  @override
  String get profileLogOut => 'Wyloguj się';

  @override
  String get profileUnsyncedTripsTitle => 'Niezsynchronizowane trasy';

  @override
  String get profileUnsyncedTripsMessage =>
      'Niektóre z zarejestrowanych punktów nie mogły zostać przesłane. Jeśli wylogujesz się teraz, zostaną utracone.';

  @override
  String get profileLogOutAnyway => 'Wyloguj mimo to';

  @override
  String profileImageSelectError(String error) {
    return 'Nie udało się wybrać zdjęcia: $error';
  }

  @override
  String get friendsTitle => 'Znajomi';

  @override
  String get friendsSearchPlaceholder => 'Wpisz nazwę użytkownika...';

  @override
  String get friendsRequestsBanner => 'Zaproszenia do znajomych';

  @override
  String friendsYourFriendsHeader(int count) {
    return 'TWOI ZNAJOMI ($count)';
  }

  @override
  String friendsInviteSent(String username) {
    return 'Wysłano zaproszenie do $username!';
  }

  @override
  String get friendsRequestsTitle => 'Zaproszenia do znajomych';

  @override
  String get friendsTabReceived => 'Odebrane';

  @override
  String get friendsTabSent => 'Wysłane';

  @override
  String friendsPlayerFog(String username) {
    return 'Mgła gracza: $username';
  }

  @override
  String get questsBoardTitle => 'Tablica zadań';

  @override
  String questsAvailableSection(int count) {
    return 'Dostępne zadania ($count)';
  }

  @override
  String questsInProgressSection(int count) {
    return 'W trakcie ($count)';
  }

  @override
  String questsCompletedSection(int count) {
    return 'Ukończone ($count)';
  }

  @override
  String get questsNoQuestsInCategory => 'Brak zadań w tej kategorii.';

  @override
  String questsProgressPercent(int percent) {
    return 'Postęp: $percent%';
  }

  @override
  String get questsCompletedStatus => 'Ukończone';

  @override
  String questsRewardXp(int points) {
    return '$points XP';
  }

  @override
  String get questsStartQuest => 'Rozpocznij zadanie';

  @override
  String get questsTypeFollowRoute => 'Przejdź trasą';

  @override
  String get questsTypeVisitPoints => 'Odwiedź punkty';

  @override
  String get questsNoDescription => 'Brak opisu.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsPolish => 'Polski';

  @override
  String get settingsSystemDefault => 'Domyślny systemu';

  @override
  String get validationUsernameRequired => 'Login jest wymagany';

  @override
  String get validationUsernameLength => 'Login musi mieć od 3 do 50 znaków';

  @override
  String get validationEmailRequired => 'Email jest wymagany';

  @override
  String get validationEmailInvalid => 'Email powinien być poprawny';

  @override
  String get validationPasswordRequired => 'Hasło jest wymagane';

  @override
  String get validationPasswordLength => 'Hasło musi mieć od 6 do 50 znaków';

  @override
  String get validationPasswordComplexity =>
      'Hasło musi zawierać wielką literę, małą literę, cyfrę i znak specjalny';

  @override
  String get errorNetwork => 'Błąd sieci. Sprawdź swoje połączenie.';

  @override
  String get errorNetworkShort => 'Błąd sieci.';

  @override
  String get errorSessionExpired => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String get errorForbidden => 'Nie masz uprawnień do wykonania tej operacji.';

  @override
  String get errorNotFound => 'Nie znaleziono.';

  @override
  String get errorTimeout => 'Upłynął limit czasu żądania. Spróbuj ponownie.';

  @override
  String get errorBackendNotConfigured =>
      'Adres URL serwera nie jest skonfigurowany.';

  @override
  String errorServer(int statusCode) {
    return 'Błąd serwera ($statusCode)';
  }

  @override
  String get errorSomethingWentWrong => 'Coś poszło nie tak.';

  @override
  String get errorSomethingWentWrongTryAgain =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get errorFailedToLoadProfile =>
      'Coś poszło nie tak. Nie udało się załadować profilu.';

  @override
  String get errorFailedToUpdateBio => 'Nie udało się zaktualizować biogramu.';

  @override
  String get errorFailedToUploadAvatar => 'Nie udało się przesłać awatara.';

  @override
  String get errorFailedToLoadQuests =>
      'Coś poszło nie tak. Nie udało się załadować zadań.';

  @override
  String get errorLocationDisabled =>
      'Usługi lokalizacji są wyłączone. Włącz je w ustawieniach urządzenia.';

  @override
  String get errorLocationPermissionRequired =>
      'Uprawnienia lokalizacji są wymagane do śledzenia podróży.';

  @override
  String get errorGoogleAuthFailed =>
      'Logowanie przez Google nie powiodło się.';

  @override
  String get locationNotificationText => 'Nagrywanie trasy w tle...';
}
