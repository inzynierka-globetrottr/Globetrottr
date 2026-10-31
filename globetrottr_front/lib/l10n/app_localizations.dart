import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Globetrottr'**
  String get appTitle;

  /// No description provided for @appLogo.
  ///
  /// In en, this message translates to:
  /// **'globetrottr'**
  String get appLogo;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authUsernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernamePlaceholder;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailPlaceholder;

  /// No description provided for @authPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordPlaceholder;

  /// No description provided for @authLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get authLoading;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get authOrContinueWith;

  /// No description provided for @authGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get authGoogleAccount;

  /// No description provided for @profileDefaultUsername.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get profileDefaultUsername;

  /// No description provided for @profileBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your journeys...'**
  String get profileBioPlaceholder;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get profileTotalPoints;

  /// No description provided for @profileStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatistics;

  /// No description provided for @profileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogOut;

  /// No description provided for @profileUnsyncedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsynced trips'**
  String get profileUnsyncedTripsTitle;

  /// No description provided for @profileUnsyncedTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'Some of your recorded points could not be uploaded. If you log out now, they will be lost.'**
  String get profileUnsyncedTripsMessage;

  /// No description provided for @profileLogOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Log out anyway'**
  String get profileLogOutAnyway;

  /// No description provided for @profileImageSelectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image: {error}'**
  String profileImageSelectError(String error);

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter friend\'s username...'**
  String get friendsSearchPlaceholder;

  /// No description provided for @friendsRequestsBanner.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendsRequestsBanner;

  /// No description provided for @friendsYourFriendsHeader.
  ///
  /// In en, this message translates to:
  /// **'YOUR FRIENDS ({count})'**
  String friendsYourFriendsHeader(int count);

  /// No description provided for @friendsInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {username}!'**
  String friendsInviteSent(String username);

  /// No description provided for @friendsRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendsRequestsTitle;

  /// No description provided for @friendsTabReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get friendsTabReceived;

  /// No description provided for @friendsTabSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsTabSent;

  /// No description provided for @friendsPlayerFog.
  ///
  /// In en, this message translates to:
  /// **'Player fog: {username}'**
  String friendsPlayerFog(String username);

  /// No description provided for @questsBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Quest Board'**
  String get questsBoardTitle;

  /// No description provided for @questsAvailableSection.
  ///
  /// In en, this message translates to:
  /// **'Available Quests ({count})'**
  String questsAvailableSection(int count);

  /// No description provided for @questsInProgressSection.
  ///
  /// In en, this message translates to:
  /// **'In Progress ({count})'**
  String questsInProgressSection(int count);

  /// No description provided for @questsCompletedSection.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String questsCompletedSection(int count);

  /// No description provided for @questsNoQuestsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No quests in this category.'**
  String get questsNoQuestsInCategory;

  /// No description provided for @questsProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% progress'**
  String questsProgressPercent(int percent);

  /// No description provided for @questsCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get questsCompletedStatus;

  /// No description provided for @questsRewardXp.
  ///
  /// In en, this message translates to:
  /// **'{points} XP'**
  String questsRewardXp(int points);

  /// No description provided for @questsStartQuest.
  ///
  /// In en, this message translates to:
  /// **'Start Quest'**
  String get questsStartQuest;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsPolish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get settingsPolish;

  /// No description provided for @settingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsSystemDefault;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Login is required'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameLength.
  ///
  /// In en, this message translates to:
  /// **'Login must be between 3 and 50 characters'**
  String get validationUsernameLength;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email should be valid'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be between 6 and 50 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter, a lowercase letter, a digit and a special character'**
  String get validationPasswordComplexity;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorNetworkShort.
  ///
  /// In en, this message translates to:
  /// **'Network error.'**
  String get errorNetworkShort;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorBackendNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Backend URL is not configured.'**
  String get errorBackendNotConfigured;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error ({statusCode})'**
  String errorServer(int statusCode);

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorSomethingWentWrong;

  /// No description provided for @errorSomethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWentWrongTryAgain;

  /// No description provided for @errorFailedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Failed to load profile.'**
  String get errorFailedToLoadProfile;

  /// No description provided for @errorFailedToUpdateBio.
  ///
  /// In en, this message translates to:
  /// **'Failed to update bio.'**
  String get errorFailedToUpdateBio;

  /// No description provided for @errorFailedToUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar.'**
  String get errorFailedToUploadAvatar;

  /// No description provided for @errorFailedToLoadQuests.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Failed to load quests.'**
  String get errorFailedToLoadQuests;

  /// No description provided for @errorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in your device settings.'**
  String get errorLocationDisabled;

  /// No description provided for @errorLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to track your trips.'**
  String get errorLocationPermissionRequired;

  /// No description provided for @errorGoogleAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Google authentication failed.'**
  String get errorGoogleAuthFailed;

  /// No description provided for @locationNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Recording your route in the background...'**
  String get locationNotificationText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
