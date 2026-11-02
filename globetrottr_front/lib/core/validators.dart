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

/// Password rules of the backend registration.
const _minPasswordLength = 6;
const _maxPasswordLength = 50;

/// A valid password this long counts as strong.
const _strongPasswordLength = 12;

String? validatePassword(String? value, [AppLocalizations? l10n]) {
  if (value == null || value.isEmpty) {
    return l10n?.validationPasswordRequired ?? 'Password is required';
  }
  if (value.length < _minPasswordLength || value.length > _maxPasswordLength) {
    return l10n?.validationPasswordLength ??
        'Password must be between 6 and 50 characters';
  }
  final hasLower = RegExp('[a-z]').hasMatch(value);
  final hasUpper = RegExp('[A-Z]').hasMatch(value);
  final hasDigit = RegExp('[0-9]').hasMatch(value);
  final hasSpecial = RegExp(r'[!@#$%^&*()\-_=+]').hasMatch(value);
  if (!hasLower || !hasUpper || !hasDigit || !hasSpecial) {
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

enum PasswordStrength { none, weak, good, strong }

/// Weak until the password meets every rule of [validatePassword].
PasswordStrength passwordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;
  if (validatePassword(password) != null) return PasswordStrength.weak;
  return password.length >= _strongPasswordLength
      ? PasswordStrength.strong
      : PasswordStrength.good;
}
