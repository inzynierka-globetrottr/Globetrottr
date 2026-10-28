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
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authUsernamePlaceholder => 'Username';

  @override
  String get authEmailPlaceholder => 'Email';

  @override
  String get authPasswordPlaceholder => 'Password';

  @override
  String get authLoading => 'Loading...';

  @override
  String get authOrContinueWith => 'OR CONTINUE WITH';

  @override
  String get authGoogleAccount => 'Google Account';

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
  String get friendsSearchPlaceholder => 'Enter friend\'s username...';

  @override
  String get friendsRequestsBanner => 'Friend requests';

  @override
  String friendsYourFriendsHeader(int count) {
    return 'YOUR FRIENDS ($count)';
  }

  @override
  String friendsInviteSent(String username) {
    return 'Invite sent to $username!';
  }

  @override
  String get friendsRequestsTitle => 'Friend Requests';

  @override
  String get friendsTabReceived => 'Received';

  @override
  String get friendsTabSent => 'Sent';

  @override
  String friendsPlayerFog(String username) {
    return 'Player fog: $username';
  }

  @override
  String get questsBoardTitle => 'Quest Board';

  @override
  String questsAvailableSection(int count) {
    return 'Available Quests ($count)';
  }

  @override
  String questsInProgressSection(int count) {
    return 'In Progress ($count)';
  }

  @override
  String questsCompletedSection(int count) {
    return 'Completed ($count)';
  }

  @override
  String get questsNoQuestsInCategory => 'No quests in this category.';

  @override
  String questsProgressPercent(int percent) {
    return '$percent% progress';
  }

  @override
  String get questsCompletedStatus => 'Completed';

  @override
  String questsRewardXp(int points) {
    return '$points XP';
  }

  @override
  String get questsStartQuest => 'Start Quest';

  @override
  String get questsTypeFollowRoute => 'Follow the route';

  @override
  String get questsTypeVisitPoints => 'Visit the points';

  @override
  String get questsNoDescription => 'No description yet.';

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
  String get errorGoogleAuthFailed => 'Google authentication failed.';

  @override
  String get locationNotificationText =>
      'Recording your route in the background...';
}
