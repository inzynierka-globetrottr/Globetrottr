import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

const String _kLocaleKey = 'app_locale';
const FlutterSecureStorage _storage = FlutterSecureStorage();

Future<Locale?> loadPersistedLocale() async {
  try {
    final code = await _storage.read(key: _kLocaleKey);
    if (code != null &&
        AppLocalizations.supportedLocales.any((l) => l.languageCode == code)) {
      return Locale(code);
    }
  } catch (_) {
    // Fall back to null on storage read errors
  }
  return null;
}

final initialLocaleProvider = Provider<Locale?>((ref) => null);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    return ref.watch(initialLocaleProvider);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      if (locale == null) {
        await _storage.delete(key: _kLocaleKey);
      } else {
        await _storage.write(key: _kLocaleKey, value: locale.languageCode);
      }
    } catch (_) {
      // Ignore storage write errors
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
