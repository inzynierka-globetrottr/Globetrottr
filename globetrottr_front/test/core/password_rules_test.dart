import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/validators.dart';

void main() {
  test('an empty password meets no rule', () {
    expect(PasswordRule.values.where((r) => r.isMetBy('')), isEmpty);
  });

  test('each rule checks one thing', () {
    expect(PasswordRule.length.isMetBy('abcdef'), isTrue);
    expect(PasswordRule.length.isMetBy('abcde'), isFalse);
    expect(PasswordRule.length.isMetBy('a' * 51), isFalse);
    expect(PasswordRule.lowercase.isMetBy('A1a'), isTrue);
    expect(PasswordRule.uppercase.isMetBy('a1A'), isTrue);
    expect(PasswordRule.digit.isMetBy('ab3'), isTrue);
    expect(PasswordRule.special.isMetBy('ab!'), isTrue);
    expect(PasswordRule.special.isMetBy('abc'), isFalse);
  });

  test('a password is good only when it meets every rule', () {
    expect(isPasswordGood('Szlak26!'), isTrue);
    expect(isPasswordGood('Szlak2026'), isFalse);
  });

  test('good agrees with the validator', () {
    for (final password in ['abc', 'Abcdef1!', 'Szlak2026', 'x' * 60]) {
      expect(
        isPasswordGood(password),
        validatePassword(password) == null,
        reason: password,
      );
    }
  });
}
