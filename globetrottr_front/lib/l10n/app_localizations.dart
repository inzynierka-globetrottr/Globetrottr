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

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get navQuests;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @mapPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String mapPercent(String value);

  /// No description provided for @mapUnknownRegion.
  ///
  /// In en, this message translates to:
  /// **'Your area'**
  String get mapUnknownRegion;

  /// No description provided for @mapNewArea.
  ///
  /// In en, this message translates to:
  /// **'+{area} km²'**
  String mapNewArea(String area);

  /// No description provided for @mapNewAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'new ground'**
  String get mapNewAreaLabel;

  /// No description provided for @mapStartWalk.
  ///
  /// In en, this message translates to:
  /// **'Start the walk'**
  String get mapStartWalk;

  /// No description provided for @mapStopWalk.
  ///
  /// In en, this message translates to:
  /// **'Stop the walk'**
  String get mapStopWalk;

  /// No description provided for @mapLayers.
  ///
  /// In en, this message translates to:
  /// **'Map layers'**
  String get mapLayers;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Center on my position'**
  String get mapRecenter;

  /// No description provided for @mapViewFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get mapViewFog;

  /// No description provided for @mapViewStreets.
  ///
  /// In en, this message translates to:
  /// **'Streets only'**
  String get mapViewStreets;

  /// No description provided for @mapViewHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Heatmap'**
  String get mapViewHeatmap;

  /// No description provided for @mapViewVoronoi.
  ///
  /// In en, this message translates to:
  /// **'Voronoi'**
  String get mapViewVoronoi;

  /// No description provided for @mapViewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This view will be available soon.'**
  String get mapViewUnavailable;

  /// No description provided for @questActive.
  ///
  /// In en, this message translates to:
  /// **'Active quest: {title}'**
  String questActive(String title);

  /// No description provided for @questDetails.
  ///
  /// In en, this message translates to:
  /// **'Quest details'**
  String get questDetails;

  /// No description provided for @questProgressShort.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String questProgressShort(String percent);

  /// No description provided for @questPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Quest · {distance}'**
  String questPointLabel(String distance);

  /// No description provided for @authSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get authSkip;

  /// No description provided for @authLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Login or nickname'**
  String get authLoginLabel;

  /// No description provided for @authNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. explorer'**
  String get authNicknamePlaceholder;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get authPasswordPlaceholder;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get authNoAccount;

  /// No description provided for @authCreateOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get authCreateOne;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authRegisterTitle;

  /// No description provided for @authNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get authNicknameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get authEmailLabel;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'address@mail.com'**
  String get authEmailPlaceholder;

  /// No description provided for @authRuleLength.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} characters'**
  String authRuleLength(int min, int max);

  /// No description provided for @authRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'a–z'**
  String get authRuleLowercase;

  /// No description provided for @authRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get authRuleUppercase;

  /// No description provided for @authRuleDigit.
  ///
  /// In en, this message translates to:
  /// **'0–9'**
  String get authRuleDigit;

  /// No description provided for @authRuleSpecial.
  ///
  /// In en, this message translates to:
  /// **'!@#'**
  String get authRuleSpecial;

  /// No description provided for @authRuleMet.
  ///
  /// In en, this message translates to:
  /// **'met'**
  String get authRuleMet;

  /// No description provided for @authRuleNotMet.
  ///
  /// In en, this message translates to:
  /// **'not met'**
  String get authRuleNotMet;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authVerifyTitle;

  /// No description provided for @authCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get authCodeSentTo;

  /// No description provided for @authCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authCodeLabel;

  /// No description provided for @authCodeValidity.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{The code is valid for 1 minute.} other{The code is valid for {minutes} minutes.}}'**
  String authCodeValidity(int minutes);

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String authResendIn(String time);

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend the code'**
  String get authResend;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password reset will be available soon.'**
  String get authResetUnavailable;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get authChangePassword;

  /// No description provided for @profileDefaultUsername.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get profileDefaultUsername;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatistics;

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

  /// No description provided for @profileRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get profileRoutes;

  /// No description provided for @profileDiscovered.
  ///
  /// In en, this message translates to:
  /// **'discovered area'**
  String get profileDiscovered;

  /// No description provided for @profileArea.
  ///
  /// In en, this message translates to:
  /// **'{area} km²'**
  String profileArea(String area);

  /// No description provided for @profileWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'New area per week'**
  String get profileWeeklyTitle;

  /// No description provided for @profileWeeklyUnit.
  ///
  /// In en, this message translates to:
  /// **'km²'**
  String get profileWeeklyUnit;

  /// No description provided for @profileWeekNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get profileWeekNow;

  /// No description provided for @profileWeekValue.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}: {area} km²'**
  String profileWeekValue(String date, String area);

  /// No description provided for @profileThisWeekValue.
  ///
  /// In en, this message translates to:
  /// **'This week: {area} km²'**
  String profileThisWeekValue(String area);

  /// No description provided for @profileDistance.
  ///
  /// In en, this message translates to:
  /// **'distance travelled'**
  String get profileDistance;

  /// No description provided for @profileDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String profileDistanceValue(String distance);

  /// No description provided for @profileCompletedQuests.
  ///
  /// In en, this message translates to:
  /// **'completed quests'**
  String get profileCompletedQuests;

  /// No description provided for @profileEarthShare.
  ///
  /// In en, this message translates to:
  /// **'of the Earth\'s land discovered'**
  String get profileEarthShare;

  /// No description provided for @profileEarthShareValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String profileEarthShareValue(String value);

  /// No description provided for @profileShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details: level {level}'**
  String profileShowDetails(String level);

  /// No description provided for @profileXpProgress.
  ///
  /// In en, this message translates to:
  /// **'{xp} / {next} XP'**
  String profileXpProgress(String xp, String next);

  /// No description provided for @profileXpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to level {level}'**
  String profileXpToNext(String xp, int level);

  /// No description provided for @profileFriendsSince.
  ///
  /// In en, this message translates to:
  /// **'Friends since {date}'**
  String profileFriendsSince(String date);

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get profileChangePhoto;

  /// No description provided for @profileOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open the map full screen'**
  String get profileOpenMap;

  /// No description provided for @profileFogMap.
  ///
  /// In en, this message translates to:
  /// **'Map of the area discovered by {username}'**
  String profileFogMap(String username);

  /// No description provided for @friendFogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the map'**
  String get friendFogLoadError;

  /// No description provided for @friendMapArea.
  ///
  /// In en, this message translates to:
  /// **'{area} km² discovered'**
  String friendMapArea(String area);

  /// No description provided for @friendMapTheirs.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s area'**
  String friendMapTheirs(String username);

  /// No description provided for @friendMapTogether.
  ///
  /// In en, this message translates to:
  /// **'Together with me'**
  String get friendMapTogether;

  /// No description provided for @friendTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get friendTabProfile;

  /// No description provided for @friendTabComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get friendTabComparison;

  /// No description provided for @friendOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get friendOnlyYou;

  /// No description provided for @friendShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get friendShared;

  /// No description provided for @friendOnlyFriend.
  ///
  /// In en, this message translates to:
  /// **'Only {username}'**
  String friendOnlyFriend(String username);

  /// No description provided for @friendSplitSummary.
  ///
  /// In en, this message translates to:
  /// **'Area: only you {you}%, shared {shared}%, only {username} {friend}%'**
  String friendSplitSummary(
    String you,
    String shared,
    String username,
    String friend,
  );

  /// No description provided for @friendDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get friendDuel;

  /// No description provided for @friendDuelDiscovered.
  ///
  /// In en, this message translates to:
  /// **'Discovered'**
  String get friendDuelDiscovered;

  /// No description provided for @friendDuelCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get friendDuelCountries;

  /// No description provided for @friendDuelQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get friendDuelQuests;

  /// No description provided for @friendDuelBetter.
  ///
  /// In en, this message translates to:
  /// **'better result'**
  String get friendDuelBetter;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get friendsAdd;

  /// No description provided for @friendsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get friendsThisWeek;

  /// No description provided for @friendsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get friendsYou;

  /// No description provided for @friendsInvites.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 invite} other{{count} invites}}'**
  String friendsInvites(int count);

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept the invite from {username}'**
  String friendsAccept(String username);

  /// No description provided for @friendsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject the invite from {username}'**
  String friendsReject(String username);

  /// No description provided for @friendsYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Your friends · {count}'**
  String friendsYourFriends(int count);

  /// No description provided for @friendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmptyTitle;

  /// No description provided for @friendsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add someone by their nickname to see how far they have explored.'**
  String get friendsEmptyBody;

  /// No description provided for @friendsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {username}'**
  String friendsOpen(String username);

  /// No description provided for @friendsLevelUnknown.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get friendsLevelUnknown;

  /// No description provided for @friendsArea.
  ///
  /// In en, this message translates to:
  /// **'{area} km²'**
  String friendsArea(String area);

  /// No description provided for @friendsNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get friendsNicknameLabel;

  /// No description provided for @friendsNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. explorer'**
  String get friendsNicknamePlaceholder;

  /// No description provided for @friendsSendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get friendsSendInvite;

  /// No description provided for @friendsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsSent;

  /// No description provided for @friendsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get friendsPending;

  /// No description provided for @friendsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get friendsUndo;

  /// No description provided for @questsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get questsTitle;

  /// No description provided for @questsLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String questsLevel(String level);

  /// No description provided for @questsXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String questsXp(String xp);

  /// No description provided for @questsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quest} other{{count} quests}}'**
  String questsCompletedCount(int count);

  /// No description provided for @questsHistoryLink.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, {completed}: history'**
  String questsHistoryLink(String level, String completed);

  /// No description provided for @questsActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active quest'**
  String get questsActiveLabel;

  /// No description provided for @questsNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active quest'**
  String get questsNoActive;

  /// No description provided for @questsPickFromList.
  ///
  /// In en, this message translates to:
  /// **'Pick a quest from the list'**
  String get questsPickFromList;

  /// No description provided for @questsPointOf.
  ///
  /// In en, this message translates to:
  /// **'Point {current} of {total}'**
  String questsPointOf(int current, int total);

  /// No description provided for @questsRouteDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} km'**
  String questsRouteDone(String done, String total);

  /// No description provided for @questsShowPoint.
  ///
  /// In en, this message translates to:
  /// **'Show point'**
  String get questsShowPoint;

  /// No description provided for @questsShowRoute.
  ///
  /// In en, this message translates to:
  /// **'Show route'**
  String get questsShowRoute;

  /// No description provided for @questsPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get questsPlaces;

  /// No description provided for @questsRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get questsRoutes;

  /// No description provided for @questsPointCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String questsPointCount(int count);

  /// No description provided for @questsKilometers.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String questsKilometers(String distance);

  /// No description provided for @questsRewardXp.
  ///
  /// In en, this message translates to:
  /// **'{points} XP'**
  String questsRewardXp(int points);

  /// No description provided for @questsStart.
  ///
  /// In en, this message translates to:
  /// **'Start quest: {title}'**
  String questsStart(String title);

  /// No description provided for @questsSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap the active quest for: {title}'**
  String questsSwap(String title);

  /// No description provided for @questsSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap the active quest?'**
  String get questsSwapTitle;

  /// No description provided for @questsSwapBody.
  ///
  /// In en, this message translates to:
  /// **'“{active}” will be cancelled and you will lose its progress ({progress}). You will start “{next}” instead.'**
  String questsSwapBody(String active, String progress, String next);

  /// No description provided for @questsSwapProgressPoint.
  ///
  /// In en, this message translates to:
  /// **'point {current} of {total}'**
  String questsSwapProgressPoint(int current, int total);

  /// No description provided for @questsSwapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get questsSwapCancel;

  /// No description provided for @questsSwapConfirm.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get questsSwapConfirm;

  /// No description provided for @questsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed quests'**
  String get questsHistoryTitle;

  /// No description provided for @questsCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'{type} · completed {date}'**
  String questsCompletedOn(String type, String date);

  /// No description provided for @questFlagPoint.
  ///
  /// In en, this message translates to:
  /// **'point {current}/{total} · {distance}'**
  String questFlagPoint(int current, int total, String distance);

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

  /// No description provided for @validationNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Nickname is required'**
  String get validationNicknameRequired;

  /// No description provided for @validationNicknameLength.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be between 3 and 50 characters'**
  String get validationNicknameLength;

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

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong login or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Confirm your e-mail address before signing in.'**
  String get errorEmailNotVerified;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong code.'**
  String get errorInvalidCode;

  /// No description provided for @errorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Send a new one.'**
  String get errorCodeExpired;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This e-mail is already in use.'**
  String get errorEmailTaken;

  /// No description provided for @errorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken.'**
  String get errorUsernameTaken;

  /// No description provided for @validationCodeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits of the code.'**
  String get validationCodeIncomplete;

  /// No description provided for @errorInviteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot invite yourself.'**
  String get errorInviteSelf;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'There is no user with this nickname.'**
  String get errorUserNotFound;

  /// No description provided for @errorAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'You are already friends.'**
  String get errorAlreadyFriends;

  /// No description provided for @errorInviteAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'An invite is already waiting for an answer.'**
  String get errorInviteAlreadySent;

  /// No description provided for @errorCannotInvite.
  ///
  /// In en, this message translates to:
  /// **'This user cannot be invited.'**
  String get errorCannotInvite;

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
