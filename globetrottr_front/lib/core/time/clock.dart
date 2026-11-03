import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time; tests replace it to move time forward.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
