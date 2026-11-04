// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Globetrottr';

  @override
  String get appLogo => 'globetrottr';

  @override
  String get navMap => 'Map';

  @override
  String get navQuests => 'Quests';

  @override
  String get navFriends => 'Friends';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String mapPercent(String value) {
    return '$value%';
  }

  @override
  String get mapUnknownRegion => 'Your area';

  @override
  String mapNewArea(String area) {
    return '+$area km²';
  }

  @override
  String get mapNewAreaLabel => 'new ground';

  @override
  String get mapStartWalk => 'Start the walk';

  @override
  String get mapStopWalk => 'Stop the walk';

  @override
  String get mapLayers => 'Map layers';

  @override
  String get mapRecenter => 'Center on my position';

  @override
  String get mapViewFog => 'Fog';

  @override
  String get mapViewStreets => 'Streets only';

  @override
  String get mapViewHeatmap => 'Heatmap';

  @override
  String get mapViewVoronoi => 'Voronoi';

  @override
  String get mapViewUnavailable => 'This view will be available soon.';

  @override
  String questActive(String title) {
    return 'Active quest: $title';
  }

  @override
  String get questDetails => 'Quest details';

  @override
  String questProgressShort(String percent) {
    return '$percent%';
  }

  @override
  String questPointLabel(String distance) {
    return 'Quest · $distance';
  }

  @override
  String get authSkip => 'Skip';

  @override
  String get authLoginLabel => 'Login or nickname';

  @override
  String get authNicknamePlaceholder => 'e.g. explorer';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordPlaceholder => '••••••••';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authNoAccount => 'No account yet?';

  @override
  String get authCreateOne => 'Create one';

  @override
  String get authRegisterTitle => 'Create an account';

  @override
  String get authNicknameLabel => 'Nickname';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailPlaceholder => 'address@mail.com';

  @override
  String authRuleLength(int min, int max) {
    return '$min–$max characters';
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
  String get authRuleMet => 'met';

  @override
  String get authRuleNotMet => 'not met';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authVerifyTitle => 'Check your inbox';

  @override
  String get authCodeSentTo => 'We sent a 6-digit code to';

  @override
  String get authCodeLabel => 'Verification code';

  @override
  String authCodeValidity(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'The code is valid for $minutes minutes.',
      one: 'The code is valid for 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get authVerify => 'Verify';

  @override
  String authResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get authResend => 'Resend the code';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authResetUnavailable => 'Password reset will be available soon.';

  @override
  String get authNewPasswordTitle => 'Set a new password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authChangePassword => 'Change password';

  @override
  String get profileDefaultUsername => 'Traveler';

  @override
  String get profileBioPlaceholder => 'Tell others about your journeys...';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSave => 'Save';

  @override
  String get profileTotalPoints => 'Total Points';

  @override
  String get profileStatistics => 'Statistics';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileLogOut => 'Log Out';

  @override
  String get profileUnsyncedTripsTitle => 'Unsynced trips';

  @override
  String get profileUnsyncedTripsMessage =>
      'Some of your recorded points could not be uploaded. If you log out now, they will be lost.';

  @override
  String get profileLogOutAnyway => 'Log out anyway';

  @override
  String profileImageSelectError(String error) {
    return 'Failed to select image: $error';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsAdd => 'Add a friend';

  @override
  String get friendsThisWeek => 'This week';

  @override
  String get friendsYou => 'You';

  @override
  String friendsInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites',
      one: '1 invite',
    );
    return '$_temp0';
  }

  @override
  String friendsAccept(String username) {
    return 'Accept the invite from $username';
  }

  @override
  String friendsReject(String username) {
    return 'Reject the invite from $username';
  }

  @override
  String friendsYourFriends(int count) {
    return 'Your friends · $count';
  }

  @override
  String get friendsEmptyTitle => 'No friends yet';

  @override
  String get friendsEmptyBody =>
      'Add someone by their nickname to see how far they have explored.';

  @override
  String friendsOpen(String username) {
    return 'Open $username';
  }

  @override
  String get friendsLevelUnknown => '–';

  @override
  String friendsArea(String area) {
    return '$area km²';
  }

  @override
  String get friendsNicknameLabel => 'Nickname';

  @override
  String get friendsNicknamePlaceholder => 'e.g. explorer';

  @override
  String get friendsSendInvite => 'Send invite';

  @override
  String get friendsSent => 'Sent';

  @override
  String get friendsPending => 'Pending';

  @override
  String get friendsUndo => 'Undo';

  @override
  String friendsPlayerFog(String username) {
    return 'Player fog: $username';
  }

  @override
  String get questsTitle => 'Quests';

  @override
  String questsLevel(String level) {
    return 'Level $level';
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
      other: '$count quests',
      one: '1 quest',
    );
    return '$_temp0';
  }

  @override
  String questsHistoryLink(String level, String completed) {
    return 'Level $level, $completed: history';
  }

  @override
  String get questsActiveLabel => 'Active quest';

  @override
  String get questsNoActive => 'No active quest';

  @override
  String get questsPickFromList => 'Pick a quest from the list';

  @override
  String questsPointOf(int current, int total) {
    return 'Point $current of $total';
  }

  @override
  String questsRouteDone(String done, String total) {
    return '$done of $total km';
  }

  @override
  String get questsShowPoint => 'Show point';

  @override
  String get questsShowRoute => 'Show route';

  @override
  String get questsPlaces => 'Places';

  @override
  String get questsRoutes => 'Routes';

  @override
  String questsPointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
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
    return 'Start quest: $title';
  }

  @override
  String questsSwap(String title) {
    return 'Swap the active quest for: $title';
  }

  @override
  String get questsSwapTitle => 'Swap the active quest?';

  @override
  String questsSwapBody(String active, String progress, String next) {
    return '“$active” will be cancelled and you will lose its progress ($progress). You will start “$next” instead.';
  }

  @override
  String questsSwapProgressPoint(int current, int total) {
    return 'point $current of $total';
  }

  @override
  String get questsSwapCancel => 'Cancel';

  @override
  String get questsSwapConfirm => 'Swap';

  @override
  String get questsHistoryTitle => 'Completed quests';

  @override
  String questsCompletedOn(String type, String date) {
    return '$type · completed $date';
  }

  @override
  String questFlagPoint(int current, int total, String distance) {
    return 'point $current/$total · $distance';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsPolish => 'Polski';

  @override
  String get settingsSystemDefault => 'System default';

  @override
  String get validationUsernameRequired => 'Login is required';

  @override
  String get validationUsernameLength =>
      'Login must be between 3 and 50 characters';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Email should be valid';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordLength =>
      'Password must be between 6 and 50 characters';

  @override
  String get validationPasswordComplexity =>
      'Password must contain an uppercase letter, a lowercase letter, a digit and a special character';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorNetworkShort => 'Network error.';

  @override
  String get errorSessionExpired => 'Session expired. Please log in again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do that.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorBackendNotConfigured => 'Backend URL is not configured.';

  @override
  String errorServer(int statusCode) {
    return 'Server error ($statusCode)';
  }

  @override
  String get errorSomethingWentWrong => 'Something went wrong.';

  @override
  String get errorSomethingWentWrongTryAgain =>
      'Something went wrong. Please try again.';

  @override
  String get errorFailedToLoadProfile =>
      'Something went wrong. Failed to load profile.';

  @override
  String get errorFailedToUpdateBio => 'Failed to update bio.';

  @override
  String get errorFailedToUploadAvatar => 'Failed to upload avatar.';

  @override
  String get errorFailedToLoadQuests =>
      'Something went wrong. Failed to load quests.';

  @override
  String get errorLocationDisabled =>
      'Location services are disabled. Please enable them in your device settings.';

  @override
  String get errorLocationPermissionRequired =>
      'Location permission is required to track your trips.';

  @override
  String get errorInvalidCredentials => 'Wrong login or password.';

  @override
  String get errorEmailNotVerified =>
      'Confirm your e-mail address before signing in.';

  @override
  String get errorInvalidCode => 'Wrong code.';

  @override
  String get errorCodeExpired => 'The code has expired. Send a new one.';

  @override
  String get errorEmailTaken => 'This e-mail is already in use.';

  @override
  String get errorUsernameTaken => 'This nickname is already taken.';

  @override
  String get validationCodeIncomplete => 'Enter all 6 digits of the code.';

  @override
  String get errorInviteSelf => 'You cannot invite yourself.';

  @override
  String get errorUserNotFound => 'There is no user with this nickname.';

  @override
  String get errorAlreadyFriends => 'You are already friends.';

  @override
  String get errorInviteAlreadySent =>
      'An invite is already waiting for an answer.';

  @override
  String get errorCannotInvite => 'This user cannot be invited.';

  @override
  String get errorGoogleAuthFailed => 'Google authentication failed.';

  @override
  String get locationNotificationText =>
      'Recording your route in the background...';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsPeriodWeek => 'Week';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsPeriodAllTime => 'All-Time';

  @override
  String get statsPrevPeriod => 'Previous period';

  @override
  String get statsNextPeriod => 'Next period';

  @override
  String get statsNewArea => 'New area';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsQuests => 'Quests';

  @override
  String get statsWeeklyNewArea => 'New area weekly';

  @override
  String get statsWeeklyChartUnitKm2 => 'km²';

  @override
  String get statsCurrentWeek => 'now';

  @override
  String get statsVisitedCountriesTitle => 'visited countries';

  @override
  String statsCountriesSummary(int regions, int cities) {
    return '$regions regions · $cities cities';
  }

  @override
  String get statsRecordsTitle => 'Records';

  @override
  String get statsRecordLongestRoute => 'Longest route';

  @override
  String get statsRecordBestDay => 'Best day';

  @override
  String get statsCitiesDiscoveryTitle => 'City discovery';

  @override
  String get statsCountriesTitle => 'Countries';

  @override
  String statsVisitedSection(int count) {
    return 'Visited · $count';
  }

  @override
  String statsCountryCardSubtitle(String area, int cities) {
    return '$area · $cities cities';
  }

  @override
  String get statsNoVisitedCountries => 'No visited countries yet';

  @override
  String get statsRegionDiscoveryTitle => 'Region discovery';

  @override
  String get statsCountiesDiscoveryTitle => 'Counties · Discovery';

  @override
  String get statsSubregionsDiscoveryTitle => 'Subregions · Discovery';

  @override
  String get statsDistrictsDiscoveryTitle => 'Districts · Discovery';

  @override
  String get statsMetricDiscovered => 'Discovered';

  @override
  String get statsMetricCities => 'Cities';

  @override
  String get statsFirstVisit => 'First visit';

  @override
  String get statsLastVisit => 'Last visit';

  @override
  String get statsLastVisitToday => 'Today';

  @override
  String get statsCityDiscoveryTitle => 'City discovery';

  @override
  String get statsNoSubregions => 'No subregions discovered';

  @override
  String statsSubregionsCount(int discovered, int total) {
    return '$discovered of $total counties';
  }

  @override
  String get statsNoDiscoveredCities => 'No discovered cities yet';

  @override
  String get statsStreaksTitle => 'Streaks';

  @override
  String get statsAppOpenStreak => 'App opened';

  @override
  String get statsRecordingStreak => 'Recording';

  @override
  String statsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsStreakMax(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Max: $_temp0';
  }
}
