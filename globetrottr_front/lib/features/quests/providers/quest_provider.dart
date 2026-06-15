import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import '../services/quest_service.dart';
import '../models/quest.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService();
});

final userQuestsProvider = FutureProvider.autoDispose<List<Quest>>((ref) async {
  print('➡️ [Riverpod] userQuestsProvider został uruchomiony! Pobieram dane...'); 
  final authService = ref.read(authServiceProvider);
  final questService = ref.read(questServiceProvider);

  final token = await authService.getToken();

  if (token == null) {
    throw Exception('User is not logged in. No token available.');
  }

  return questService.fetchUserQuests(token);
});