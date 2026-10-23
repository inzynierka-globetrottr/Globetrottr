import 'package:flutter/widgets.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

extension LocalizedErrorExtension on BuildContext {
  String localizeErrorMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return l10n.errorSomethingWentWrong;
    }
    return translateErrorMessage(message, l10n);
  }
}

String translateErrorMessage(String message, AppLocalizations l10n) {
  final trimmed = message.trim();

  if (trimmed.startsWith('Server error (')) {
    final match = RegExp(r'^Server error \((\d+)\)$').firstMatch(trimmed);
    if (match != null) {
      final code = int.tryParse(match.group(1) ?? '') ?? 0;
      return l10n.errorServer(code);
    }
  }

  return switch (trimmed) {
    'Session expired. Please log in again.' => l10n.errorSessionExpired,
    "You don't have permission to do that." => l10n.errorForbidden,
    'Not found.' => l10n.errorNotFound,
    'Network error. Please check your connection.' => l10n.errorNetwork,
    'Network error.' => l10n.errorNetworkShort,
    'Request timed out. Please try again.' => l10n.errorTimeout,
    'Backend URL is not configured.' => l10n.errorBackendNotConfigured,
    'Something went wrong.' => l10n.errorSomethingWentWrong,
    'Something went wrong. Please try again.' =>
      l10n.errorSomethingWentWrongTryAgain,
    'Something went wrong. Failed to load profile.' =>
      l10n.errorFailedToLoadProfile,
    'Failed to update bio.' => l10n.errorFailedToUpdateBio,
    'Failed to upload avatar.' => l10n.errorFailedToUploadAvatar,
    'Something went wrong. Failed to load quests.' =>
      l10n.errorFailedToLoadQuests,
    'Email is required' => l10n.validationEmailRequired,
    'Google authentication failed.' => l10n.errorGoogleAuthFailed,
    'Location services are disabled. Please enable them in your device settings.' =>
      l10n.errorLocationDisabled,
    'Location permission is required to track your trips.' =>
      l10n.errorLocationPermissionRequired,
    'Recording your route in the background...' =>
      l10n.locationNotificationText,
    _ => trimmed,
  };
}

/// Programmatic translation outside widget trees utilizing generated AppLocalizations.
String translateErrorDart(String message, {String locale = 'en'}) {
  final l10n = lookupAppLocalizations(Locale(locale));
  return translateErrorMessage(message, l10n);
}
