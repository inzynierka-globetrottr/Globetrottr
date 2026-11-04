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
  String get profileCancel => 'Anuluj';

  @override
  String get profileStatistics => 'Statystyki';

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
  String get profileRoutes => 'Trasy';

  @override
  String get profileDiscovered => 'odkrytego terenu';

  @override
  String profileArea(String area) {
    return '$area km²';
  }

  @override
  String get profileWeeklyTitle => 'Nowy teren tygodniowo';

  @override
  String get profileWeeklyUnit => 'km²';

  @override
  String get profileWeekNow => 'teraz';

  @override
  String profileWeekValue(String date, String area) {
    return 'Tydzień od $date: $area km²';
  }

  @override
  String profileThisWeekValue(String area) {
    return 'Ten tydzień: $area km²';
  }

  @override
  String get profileDistance => 'przebyty dystans';

  @override
  String profileDistanceValue(String distance) {
    return '$distance km';
  }

  @override
  String get profileCompletedQuests => 'ukończone questy';

  @override
  String get profileEarthShare => 'lądów Ziemi odkrytych';

  @override
  String profileEarthShareValue(String value) {
    return '$value %';
  }

  @override
  String profileShowDetails(String level) {
    return 'Pokaż szczegóły: poziom $level';
  }

  @override
  String profileXpProgress(String xp, String next) {
    return '$xp / $next XP';
  }

  @override
  String profileXpToNext(String xp, int level) {
    return '$xp XP do poziomu $level';
  }

  @override
  String profileFriendsSince(String date) {
    return 'Znajomi od $date';
  }

  @override
  String get profileChangePhoto => 'Zmień zdjęcie profilowe';

  @override
  String get profileOpenMap => 'Otwórz mapę na pełnym ekranie';

  @override
  String profileFogMap(String username) {
    return 'Mapa z terenem odkrytym przez $username';
  }

  @override
  String get friendFogLoadError => 'Nie udało się wczytać mapy';

  @override
  String friendMapArea(String area) {
    return '$area km² odkrytego terenu';
  }

  @override
  String friendMapTheirs(String username) {
    return 'Teren $username';
  }

  @override
  String get friendMapTogether => 'Razem ze mną';

  @override
  String get friendTabProfile => 'Profil';

  @override
  String get friendTabComparison => 'Porównanie';

  @override
  String get friendOnlyYou => 'Tylko Ty';

  @override
  String get friendShared => 'Wspólne';

  @override
  String friendOnlyFriend(String username) {
    return 'Tylko $username';
  }

  @override
  String friendSplitSummary(
    String you,
    String shared,
    String username,
    String friend,
  ) {
    return 'Podział terenu: tylko Ty $you%, wspólne $shared%, tylko $username $friend%';
  }

  @override
  String get friendDuel => 'Pojedynek';

  @override
  String get friendDuelDiscovered => 'Odkryto';

  @override
  String get friendDuelCountries => 'Kraje';

  @override
  String get friendDuelQuests => 'Questy';

  @override
  String get friendDuelBetter => 'lepszy wynik';

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
  String get questsTitle => 'Questy';

  @override
  String questsLevel(String level) {
    return 'Poziom $level';
  }

  @override
  String questsXp(String xp) {
    return '$xp XP';
  }

  @override
  String questsCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questu',
      many: '$count questów',
      few: '$count questy',
      one: '1 quest',
    );
    return '$_temp0';
  }

  @override
  String questsHistoryLink(String level, String completed) {
    return 'Poziom $level, $completed: historia';
  }

  @override
  String get questsActiveLabel => 'Aktywny quest';

  @override
  String get questsNoActive => 'Brak aktywnego questa';

  @override
  String get questsPickFromList => 'Wybierz quest z listy';

  @override
  String questsPointOf(int current, int total) {
    return 'Punkt $current z $total';
  }

  @override
  String questsRouteDone(String done, String total) {
    return '$done z $total km';
  }

  @override
  String get questsShowPoint => 'Pokaż punkt';

  @override
  String get questsShowRoute => 'Pokaż trasę';

  @override
  String get questsPlaces => 'Miejsca';

  @override
  String get questsRoutes => 'Trasy';

  @override
  String questsPointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punktu',
      many: '$count punktów',
      few: '$count punkty',
      one: '1 punkt',
    );
    return '$_temp0';
  }

  @override
  String questsKilometers(String distance) {
    return '$distance km';
  }

  @override
  String questsRewardXp(int points) {
    return '$points XP';
  }

  @override
  String questsStart(String title) {
    return 'Rozpocznij quest: $title';
  }

  @override
  String questsSwap(String title) {
    return 'Zamień aktywny quest na: $title';
  }

  @override
  String get questsSwapTitle => 'Zamienić aktywny quest?';

  @override
  String questsSwapBody(String active, String progress, String next) {
    return '„$active” zostanie anulowany i stracisz postęp ($progress). Zamiast niego zaczniesz „$next”.';
  }

  @override
  String questsSwapProgressPoint(int current, int total) {
    return 'punkt $current z $total';
  }

  @override
  String get questsSwapCancel => 'Anuluj';

  @override
  String get questsSwapConfirm => 'Zamień';

  @override
  String get questsHistoryTitle => 'Ukończone questy';

  @override
  String questsCompletedOn(String type, String date) {
    return '$type · ukończono $date';
  }

  @override
  String questFlagPoint(int current, int total, String distance) {
    return 'punkt $current/$total · $distance';
  }

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
}
