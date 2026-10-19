import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';

class SyncService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<bool> syncPendingPoints(String token) async {
    if (_backendUrl.isEmpty) return false;

    final points = await MapStorage().getPendingPoints();

    if (points.isEmpty) return true;

    try {
      final List<Map<String, dynamic>> pointsJson = points
          .map((p) => p.toMap())
          .toList();
      final requestBody = jsonEncode({'points': pointsJson});

      final response = await http.post(
        Uri.parse('$_backendUrl/api/map/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final lastSyncedId = points.map((p) => p.id!).reduce(math.max);
        await MapStorage().deletePendingPointsUpTo(lastSyncedId);
        debugPrint('Local DB was cleared');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sync Error: $e');
      return false;
    }
  }
}
