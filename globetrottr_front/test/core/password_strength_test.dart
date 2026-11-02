import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/validators.dart';

void main() {
  test('an empty password has no strength yet', () {
    expect(passwordStrength(''), PasswordStrength.none);
  });

  test('a password the backend would reject is weak', () {
    expect(passwordStrength('szlak'), PasswordStrength.weak);
    expect(passwordStrength('szlak2026'), PasswordStrength.weak);
    expect(passwordStrength('Szlak2026'), PasswordStrength.weak);
  });

  test('a password meeting every rule is good', () {
    expect(passwordStrength('Szlak26!'), PasswordStrength.good);
  });

  test('a long password meeting every rule is strong', () {
    expect(passwordStrength('Szlak-Wislany26'), PasswordStrength.strong);
  });

  test('strength agrees with the validator', () {
    for (final password in ['abc', 'Abcdef1!', 'Szlak2026', 'x' * 60]) {
      final valid = validatePassword(password) == null;
      final strength = passwordStrength(password);
      expect(
        strength == PasswordStrength.good ||
            strength == PasswordStrength.strong,
        valid,
        reason: password,
      );
    }
  });
}
