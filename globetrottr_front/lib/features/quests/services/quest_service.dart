import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/quest.dart';

class QuestService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';

  Future<List<Quest>> fetchUserQuests(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/quests/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quest.fromJson(json)).toList();
    } else {
      throw Exception('Błąd pobierania questów: Kod ${response.statusCode}');
    }
  }

  Future<void> startQuest(String userId, int questId, String token) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/quests/$userId/start/$questId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Nie udało się rozpocząć questa (Kod: ${response.statusCode})');
    }
  }
}