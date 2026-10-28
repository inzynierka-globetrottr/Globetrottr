import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';

class QuestService {
  final ApiClient _client;
  QuestService(this._client);

  // TODO(fog): progress comes from the server fog polygon, not the fog shown
  // on the device; compute it from FogQuery or from server-side tiles.
  Future<List<Quest>> fetchUserQuests() async {
    final response = await _client.get('/api/quests/me');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Quest.fromJson(json)).toList();
  }

  Future<void> startQuest(int questId) =>
      _client.post('/api/quests/me/start/$questId');
}

final questServiceProvider = Provider<QuestService>(
  (ref) => QuestService(ref.read(apiClientProvider)),
);
