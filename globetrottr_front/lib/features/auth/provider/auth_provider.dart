import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/auth/provider/auth_notifier.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
