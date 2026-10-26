import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  group('Validators with localization', () {
    late AppLocalizations en;
    late AppLocalizations pl;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      pl = await AppLocalizations.delegate.load(const Locale('pl'));
    });

    test('validateUsername returns localized errors', () {
      expect(validateUsername('', en), 'Login is required');
      expect(validateUsername('', pl), 'Login jest wymagany');

      expect(
        validateUsername('ab', en),
        'Login must be between 3 and 50 characters',
      );
      expect(validateUsername('ab', pl), 'Login musi mieć od 3 do 50 znaków');

      expect(validateUsername('validUser', en), isNull);
      expect(validateUsername('validUser', pl), isNull);
    });

    test('validateEmail returns localized errors', () {
      expect(validateEmail('', en), 'Email is required');
      expect(validateEmail('', pl), 'Email jest wymagany');

      expect(validateEmail('invalid-email', en), 'Email should be valid');
      expect(validateEmail('invalid-email', pl), 'Email powinien być poprawny');

      expect(validateEmail('user@example.com', en), isNull);
      expect(validateEmail('user@example.com', pl), isNull);
    });

    test('validatePassword returns localized errors', () {
      expect(validatePassword('', en), 'Password is required');
      expect(validatePassword('', pl), 'Hasło jest wymagane');

      expect(
        validatePassword('123', en),
        'Password must be between 6 and 50 characters',
      );
      expect(validatePassword('123', pl), 'Hasło musi mieć od 6 do 50 znaków');

      expect(
        validatePassword('weakpassword', en),
        'Password must contain an uppercase letter, a lowercase letter, a digit and a special character',
      );
      expect(
        validatePassword('weakpassword', pl),
        'Hasło musi zawierać wielką literę, małą literę, cyfrę i znak specjalny',
      );

      expect(validatePassword('ValidPass1!', en), isNull);
      expect(validatePassword('ValidPass1!', pl), isNull);
    });
  });
}
