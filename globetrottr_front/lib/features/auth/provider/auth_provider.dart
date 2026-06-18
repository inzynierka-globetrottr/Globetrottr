import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_notifier.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final authStateProvider = FutureProvider<bool>((ref) async {
  try {
    final token = await AuthService().refreshToken();
    return token != null;
  } catch (_) {
    return false;
  }
});
