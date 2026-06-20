String? validateUsername(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Login is required';
  }
  final length = value.trim().length;
  if (length < 3 || length > 50) {
    return 'Login must be between 3 and 50 characters';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Email should be valid';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6 || value.length > 50) {
    return 'Password must be between 6 and 50 characters';
  }
  final hasLower = RegExp('[a-z]').hasMatch(value);
  final hasUpper = RegExp('[A-Z]').hasMatch(value);
  final hasDigit = RegExp('[0-9]').hasMatch(value);
  final hasSpecial = RegExp(r'[!@#$%^&*()\-_=+]').hasMatch(value);
  if (!hasLower || !hasUpper || !hasDigit || !hasSpecial) {
    return 'Password must contain at least one digit and one special character';
  }
  return null;
}
