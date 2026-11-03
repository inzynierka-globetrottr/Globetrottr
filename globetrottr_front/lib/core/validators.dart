import 'package:globetrottr_front/l10n/app_localizations.dart';

String? validateUsername(String? value, [AppLocalizations? l10n]) {
  if (value == null || value.trim().isEmpty) {
    return l10n?.validationUsernameRequired ?? 'Login is required';
  }
  final length = value.trim().length;
  if (length < 3 || length > 50) {
    return l10n?.validationUsernameLength ??
        'Login must be between 3 and 50 characters';
  }
  return null;
}

String? validateEmail(String? value, [AppLocalizations? l10n]) {
  if (value == null || value.trim().isEmpty) {
    return l10n?.validationEmailRequired ?? 'Email is required';
  }
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return l10n?.validationEmailInvalid ?? 'Email should be valid';
  }
  return null;
}

/// Rules of the backend registration a password must meet.
enum PasswordRule {
  length,
  lowercase,
  uppercase,
  digit,
  special;

  static const minLength = 6;
  static const maxLength = 50;

  bool isMetBy(String password) => switch (this) {
    PasswordRule.length =>
      password.length >= minLength && password.length <= maxLength,
    PasswordRule.lowercase => RegExp('[a-z]').hasMatch(password),
    PasswordRule.uppercase => RegExp('[A-Z]').hasMatch(password),
    PasswordRule.digit => RegExp('[0-9]').hasMatch(password),
    PasswordRule.special => RegExp(r'[!@#$%^&*()\-_=+]').hasMatch(password),
  };
}

/// Good when it meets every [PasswordRule].
bool isPasswordGood(String password) =>
    PasswordRule.values.every((rule) => rule.isMetBy(password));

String? validatePassword(String? value, [AppLocalizations? l10n]) {
  if (value == null || value.isEmpty) {
    return l10n?.validationPasswordRequired ?? 'Password is required';
  }
  if (!PasswordRule.length.isMetBy(value)) {
    return l10n?.validationPasswordLength ??
        'Password must be between 6 and 50 characters';
  }
  if (!isPasswordGood(value)) {
    return l10n?.validationPasswordComplexity ??
        'Password must contain an uppercase letter, a lowercase letter, a digit and a special character';
  }
  return null;
}

/// Signing in checks only that a password was typed; the rules may have
/// changed since the account was created.
String? validatePasswordPresent(String? value, [AppLocalizations? l10n]) {
  if (value == null || value.isEmpty) {
    return l10n?.validationPasswordRequired ?? 'Password is required';
  }
  return null;
}
