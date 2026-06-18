extension StringInitial on String {
  String get initialOrFallback => isNotEmpty ? this[0].toUpperCase() : '?';
}