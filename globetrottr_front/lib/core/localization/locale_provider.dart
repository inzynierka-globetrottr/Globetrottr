import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kLocaleKey = 'app_locale';

class LocaleNotifier extends Notifier<Locale?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Locale? build() {
    Future.microtask(_loadPersistedLocale);
    return null;
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final code = await _storage.read(key: _kLocaleKey);
      if (code != null && (code == 'en' || code == 'pl')) {
        state = Locale(code);
      }
    } catch (_) {
      // Graceful fallback to null (system default)
    }
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
