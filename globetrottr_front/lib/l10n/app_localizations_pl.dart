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
  String get navMap => 'Mapa';

  @override
  String get navQuests => 'Questy';

  @override
  String get navFriends => 'Znajomi';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonBack => 'Wróć';

  @override
  String get commonClose => 'Zamknij';

  @override
  String mapPercent(String value) {
    return '$value%';
  }

  @override
  String get mapUnknownRegion => 'Twoja okolica';

  @override
  String mapNewArea(String area) {
    return '+$area km²';
  }

  @override
  String get mapNewAreaLabel => 'nowy teren';

  @override
  String get mapStartWalk => 'Rozpocznij spacer';

  @override
  String get mapStopWalk => 'Zakończ spacer';

  @override
  String get mapLayers => 'Warstwy mapy';

  @override
  String get mapRecenter => 'Wyśrodkuj na mojej pozycji';

  @override
  String get mapViewFog => 'Mgła';

  @override
  String get mapViewStreets => 'Same ulice';

  @override
  String get mapViewHeatmap => 'Heatmap';

  @override
  String get mapViewVoronoi => 'Voronoi';

  @override
  String get mapViewUnavailable => 'Ten widok będzie dostępny wkrótce.';

  @override
  String questActive(String title) {
    return 'Aktywny quest: $title';
  }

  @override
  String get questDetails => 'Szczegóły questa';

  @override
  String questProgressShort(String percent) {
    return '$percent%';
  }

  @override
  String questPointLabel(String distance) {
    return 'Quest · $distance';
  }

  @override
  String get authSkip => 'Pomiń';

  @override
  String get authLoginLabel => 'Login lub nick';

  @override
  String get authNicknamePlaceholder => 'np. odkrywca';

  @override
  String get authPasswordLabel => 'Hasło';

  @override
  String get authPasswordPlaceholder => '••••••••';

  @override
  String get authShowPassword => 'Pokaż hasło';

  @override
  String get authHidePassword => 'Ukryj hasło';

  @override
  String get authForgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get authSignIn => 'Zaloguj się';

  @override
  String get authOr => 'lub';

  @override
  String get authContinueWithGoogle => 'Kontynuuj z Google';

  @override
  String get authNoAccount => 'Nie masz konta?';

  @override
  String get authCreateOne => 'Załóż je';

  @override
  String get authRegisterTitle => 'Załóż konto';

  @override
  String get authNicknameLabel => 'Nick';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailPlaceholder => 'adres@poczta.pl';

  @override
  String authRuleLength(int min, int max) {
    return '$min–$max znaków';
  }

  @override
  String get authRuleLowercase => 'a–z';

  @override
  String get authRuleUppercase => 'A–Z';

  @override
  String get authRuleDigit => '0–9';

  @override
  String get authRuleSpecial => '!@#';

  @override
  String get authRuleMet => 'spełnione';

  @override
  String get authRuleNotMet => 'niespełnione';

  @override
  String get authCreateAccount => 'Utwórz konto';

  @override
  String get authHaveAccount => 'Masz już konto?';

  @override
  String get authVerifyTitle => 'Sprawdź skrzynkę';

  @override
  String get authCodeSentTo => 'Wysłaliśmy 6-cyfrowy kod na';

  @override
  String get authCodeLabel => 'Kod weryfikacyjny';

  @override
  String authCodeValidity(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Kod jest ważny $minutes minut.',
      few: 'Kod jest ważny $minutes minuty.',
      one: 'Kod jest ważny 1 minutę.',
    );
    return '$_temp0';
  }

  @override
  String get authVerify => 'Zweryfikuj';

  @override
  String authResendIn(String time) {
    return 'Wyślij ponownie za $time';
  }

  @override
  String get authResend => 'Wyślij ponownie';

  @override
  String get authSendCode => 'Wyślij kod';

  @override
  String get authResetUnavailable => 'Reset hasła będzie dostępny wkrótce.';

  @override
  String get authNewPasswordTitle => 'Ustaw nowe hasło';

  @override
  String get authNewPasswordLabel => 'Nowe hasło';

  @override
  String get authChangePassword => 'Zmień hasło';

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
  String get friendsAdd => 'Dodaj znajomego';

  @override
  String get friendsThisWeek => 'W tym tygodniu';

  @override
  String get friendsYou => 'Ty';

  @override
  String friendsInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zaproszeń',
      few: '$count zaproszenia',
      one: '1 zaproszenie',
    );
    return '$_temp0';
  }

  @override
  String friendsAccept(String username) {
    return 'Przyjmij zaproszenie od $username';
  }

  @override
  String friendsReject(String username) {
    return 'Odrzuć zaproszenie od $username';
  }

  @override
  String friendsYourFriends(int count) {
    return 'Twoi znajomi · $count';
  }

  @override
  String get friendsEmptyTitle => 'Nie masz jeszcze znajomych';

  @override
  String get friendsEmptyBody =>
      'Dodaj kogoś po nicku, żeby zobaczyć, jak daleko zaszedł.';

  @override
  String friendsOpen(String username) {
    return 'Otwórz $username';
  }

  @override
  String get friendsLevelUnknown => '–';

  @override
  String friendsArea(String area) {
    return '$area km²';
  }

  @override
  String get friendsNicknameLabel => 'Nick';

  @override
  String get friendsNicknamePlaceholder => 'np. odkrywca';

  @override
  String get friendsSendInvite => 'Wyślij zaproszenie';

  @override
  String get friendsSent => 'Wysłane';

  @override
  String get friendsPending => 'Oczekuje';

  @override
  String get friendsUndo => 'Cofnij';

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
  String questsProgressPercent(String percent) {
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
  String get errorInvalidCredentials => 'Nieprawidłowy login lub hasło.';

  @override
  String get errorEmailNotVerified =>
      'Potwierdź adres e-mail, zanim się zalogujesz.';

  @override
  String get errorInvalidCode => 'Nieprawidłowy kod.';

  @override
  String get errorCodeExpired => 'Kod wygasł. Wyślij nowy.';

  @override
  String get errorEmailTaken => 'Ten e-mail jest już zajęty.';

  @override
  String get errorUsernameTaken => 'Ten nick jest już zajęty.';

  @override
  String get validationCodeIncomplete => 'Wpisz wszystkie 6 cyfr kodu.';

  @override
  String get errorInviteSelf => 'Nie możesz zaprosić samego siebie.';

  @override
  String get errorUserNotFound => 'Nie ma użytkownika o takim nicku.';

  @override
  String get errorAlreadyFriends => 'Jesteście już znajomymi.';

  @override
  String get errorInviteAlreadySent => 'Zaproszenie już czeka na odpowiedź.';

  @override
  String get errorCannotInvite => 'Tego użytkownika nie można zaprosić.';

  @override
  String get errorGoogleAuthFailed =>
      'Logowanie przez Google nie powiodło się.';

  @override
  String get locationNotificationText => 'Nagrywanie trasy w tle...';

  @override
  String get statsTitle => 'Statystyki';

  @override
  String get statsPeriodWeek => 'Tydzień';

  @override
  String get statsPeriodMonth => 'Miesiąc';

  @override
  String get statsPeriodYear => 'Rok';

  @override
  String get statsPeriodAllTime => 'Zawsze';

  @override
  String get statsPrevPeriod => 'Poprzedni okres';

  @override
  String get statsNextPeriod => 'Następny okres';

  @override
  String get statsNewArea => 'Nowy teren';

  @override
  String get statsDistance => 'Dystans';

  @override
  String get statsNewStreets => 'Nowe ulice';

  @override
  String get statsQuests => 'Questy';

  @override
  String get statsWeeklyNewArea => 'Nowy teren tygodniowo';

  @override
  String get statsWeeklyChartUnitKm2 => 'km²';

  @override
  String get statsCurrentWeek => 'teraz';

  @override
  String get statsVisitedCountriesTitle => 'odwiedzone kraje';

  @override
  String statsCountriesSummary(int regions, int cities) {
    return '$regions regionów · $cities miast';
  }

  @override
  String get statsDistanceByActivity => 'Dystans według aktywności · km';

  @override
  String get statsActivityWalk => 'Pieszo';

  @override
  String get statsActivityBike => 'Rower';

  @override
  String get statsActivityRun => 'Bieg';

  @override
  String get statsActivityOther => 'Inne';

  @override
  String get statsRecordsTitle => 'Rekordy';

  @override
  String get statsRecordHighest => 'Najwyżej';

  @override
  String get statsRecordFurthest => 'Najdalej';

  @override
  String get statsRecordLongestRoute => 'Najdłuższa trasa';

  @override
  String get statsRecordBestDay => 'Najlepszy dzień';

  @override
  String get statsCitiesDiscoveryTitle => 'Odkrycie miast';

  @override
  String get statsMostVisitedTitle => 'Najczęściej odwiedzane';

  @override
  String get statsCountriesTitle => 'Kraje';

  @override
  String statsVisitedSection(int count) {
    return 'Odwiedzone · $count';
  }

  @override
  String statsCountryCardSubtitle(String area, int cities) {
    return '$area · $cities miast';
  }

  @override
  String get statsNoVisitedCountries => 'Brak odwiedzonych krajów';

  @override
  String get statsRegionDiscoveryTitle => 'Odkrycie regionu';

  @override
  String get statsCountiesDiscoveryTitle => 'Powiaty · Odkrycie';

  @override
  String get statsMetricDiscovered => 'Odkryto';

  @override
  String get statsMetricCities => 'Miasta';

  @override
  String get statsMetricStreets => 'Ulice';

  @override
  String get statsMetricRoutes => 'Trasy';

  @override
  String get statsFirstVisit => 'Pierwsza wizyta';

  @override
  String get statsLastVisit => 'Ostatnia wizyta';

  @override
  String get statsLastVisitToday => 'Dziś';

  @override
  String get statsTimeSpent => 'Spędzony czas';

  @override
  String get statsCityDiscoveryTitle => 'Odkrycie miasta';

  @override
  String get statsDistrictsDiscoveryTitle => 'Dzielnice · Odkrycie';

  @override
  String get statsSubregionsDiscoveryTitle => 'Podregiony · Odkrycie';

  @override
  String get statsNoSubregions => 'Brak odkrytych podregionów';

  @override
  String statsSubregionsCount(int discovered, int total) {
    return '$discovered z $total powiatów';
  }

  @override
  String get statsNoDiscoveredCities => 'Brak odkrytych miast';

  @override
  String get statsNoVisitedPlaces => 'Brak odwiedzonych miejsc';
}
