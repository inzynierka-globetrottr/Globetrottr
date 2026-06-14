import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import '../services/quest_service.dart';
import '../models/quest.dart';

// Provider udostępniający instancję AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider udostępniający instancję QuestService
final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService();
});

// Zmieniony provider: sam pobiera ID i Token, nie musimy mu ich przekazywać z UI!
final userQuestsProvider = FutureProvider<List<Quest>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final questService = ref.read(questServiceProvider);
  
  // 1. Pobieramy dane zalogowanego użytkownika
  final userId = await authService.getUserId();
  final token = await authService.getToken();

  // 2. Weryfikacja
  if (userId == null || token == null) {
    throw Exception('Użytkownik nie jest zalogowany. Brak ID lub tokena.');
  }

  // 3. Strzał do API
  return questService.fetchUserQuests(userId, token);
});