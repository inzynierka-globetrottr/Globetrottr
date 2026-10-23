import 'package:flutter/widgets.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';

extension LocalizedErrorExtension on BuildContext {
  String localizeErrorMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return l10n.errorSomethingWentWrong;
    }

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
      _ => trimmed,
    };
  }
}

/// Fallback dictionary for programmatic Dart translation outside widget trees.
const Map<String, Map<String, String>> dartErrorTranslations = {
  'en': {
    'Session expired. Please log in again.':
        'Session expired. Please log in again.',
    "You don't have permission to do that.":
        "You don't have permission to do that.",
    'Not found.': 'Not found.',
    'Network error. Please check your connection.':
        'Network error. Please check your connection.',
    'Network error.': 'Network error.',
    'Request timed out. Please try again.':
        'Request timed out. Please try again.',
    'Backend URL is not configured.': 'Backend URL is not configured.',
    'Something went wrong.': 'Something went wrong.',
    'Something went wrong. Please try again.':
        'Something went wrong. Please try again.',
    'Something went wrong. Failed to load profile.':
        'Something went wrong. Failed to load profile.',
    'Failed to update bio.': 'Failed to update bio.',
    'Failed to upload avatar.': 'Failed to upload avatar.',
    'Something went wrong. Failed to load quests.':
        'Something went wrong. Failed to load quests.',
    'Email is required': 'Email is required',
    'Google authentication failed.': 'Google authentication failed.',
    'Location services are disabled. Please enable them in your device settings.':
        'Location services are disabled. Please enable them in your device settings.',
    'Location permission is required to track your trips.':
        'Location permission is required to track your trips.',
  },
  'pl': {
    'Session expired. Please log in again.':
        'Sesja wygasła. Zaloguj się ponownie.',
    "You don't have permission to do that.":
        'Nie masz uprawnień do wykonania tej operacji.',
    'Not found.': 'Nie znaleziono.',
    'Network error. Please check your connection.':
        'Błąd sieci. Sprawdź swoje połączenie.',
    'Network error.': 'Błąd sieci.',
    'Request timed out. Please try again.':
        'Upłynął limit czasu żądania. Spróbuj ponownie.',
    'Backend URL is not configured.':
        'Adres URL serwera nie jest skonfigurowany.',
    'Something went wrong.': 'Coś poszło nie tak.',
    'Something went wrong. Please try again.':
        'Coś poszło nie tak. Spróbuj ponownie.',
    'Something went wrong. Failed to load profile.':
        'Coś poszło nie tak. Nie udało się załadować profilu.',
    'Failed to update bio.': 'Nie udało się zaktualizować biogramu.',
    'Failed to upload avatar.': 'Nie udało się przesłać awatara.',
    'Something went wrong. Failed to load quests.':
        'Coś poszło nie tak. Nie udało się załadować zadań.',
    'Email is required': 'Email jest wymagany',
    'Google authentication failed.': 'Logowanie przez Google nie powiodło się.',
    'Location services are disabled. Please enable them in your device settings.':
        'Usługi lokalizacji są wyłączone. Włącz je w ustawieniach urządzenia.',
    'Location permission is required to track your trips.':
        'Uprawnienia lokalizacji są wymagane do śledzenia podróży.',
  },
};

String translateErrorDart(String message, {String locale = 'en'}) {
  if (message.startsWith('Server error (')) {
    final match = RegExp(r'^Server error \((\d+)\)$').firstMatch(message);
    if (match != null) {
      final code = match.group(1) ?? '';
      return locale == 'pl' ? 'Błąd serwera ($code)' : 'Server error ($code)';
    }
  }

  return dartErrorTranslations[locale]?[message] ??
      dartErrorTranslations['en']?[message] ??
      message;
}
