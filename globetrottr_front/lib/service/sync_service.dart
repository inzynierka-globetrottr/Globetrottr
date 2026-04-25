import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../database/database_helper.dart';

class SyncService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<void> syncPendingPoints() async {
    if (_backendUrl.isEmpty) return;

    final points = await DatabaseHelper().getPendingPoints();

    if (points.isEmpty) return;

    try {
      final List<Map<String, dynamic>> pointsJson = points
          .map((p) => p.toMap())
          .toList();
      final requestBody = jsonEncode({'points': pointsJson});

      final response = await http.post(
        Uri.parse('$_backendUrl/api/map/sync'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await DatabaseHelper().clearPendingPoints();
      }
    } catch (e) {
      print('Sync Error: $e');
    }
  }
}
