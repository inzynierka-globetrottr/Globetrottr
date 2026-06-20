import 'dart:convert';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/features/quests/models/quest.dart';

class QuestService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<List<Quest>> fetchUserQuests(String token) async {
    if (_backendUrl.isEmpty)
      throw AppException('Backend URL is not configured.');

    final response = await http.get(
      Uri.parse('$_backendUrl/api/quests/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quest.fromJson(json)).toList();
    } else {
      // TODO: change exception to appexception or sometheing like that
      throw Exception('Failed to fetch quests: code ${response.statusCode}');
    }
  }

  Future<void> startQuest(int questId, String token) async {
    if (_backendUrl.isEmpty)
      throw AppException('Backend URL is not configured.');

    final response = await http.post(
      Uri.parse('$_backendUrl/api/quests/me/start/$questId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      // TODO: change exception to appexception or sometheing like that
      throw Exception('Failed to start quest: code ${response.statusCode}');
    }
  }
}
