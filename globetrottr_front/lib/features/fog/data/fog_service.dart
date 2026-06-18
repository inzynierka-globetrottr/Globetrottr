import 'dart:convert';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';

// TODO: make this more in line with other service classes for consistency
class FogService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<List<List<LatLng>>> getFriendFog(String friendUsername) async {
    if (_backendUrl.isEmpty) throw AppException('Backend URL is not configured.');

    final token = await AuthService().getToken();
    if (token == null) throw Exception('User not authenticated.');

    final response = await http.get(
      Uri.parse('$_backendUrl/api/fog/$friendUsername'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return _parseMultiPolygon(response.body);
    } else {
      throw Exception('Failed to load friend fog: ${response.statusCode}');
    }
  }

  List<List<LatLng>> _parseMultiPolygon(String responseBody) {
    final Map<String, dynamic> data = jsonDecode(responseBody);

    final dynamic coordinates = data['coordinates'];

    if (coordinates == null) return [];

    List<List<LatLng>> holes = [];
    final String type = data['type'] ?? 'Polygon';

    if (type == 'Polygon') {
      for (var ring in coordinates) {
        holes.add(_parseRing(ring));
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        for (var ring in polygon) {
          holes.add(_parseRing(ring));
        }
      }
    }

    return holes;
  }

  List<LatLng> _parseRing(dynamic ring) {
    List<LatLng> polygonRing = [];
    if (ring is List) {
      for (var point in ring) {
        if (point is List && point.length >= 2) {
          final double lng = (point[0] as num).toDouble();
          final double lat = (point[1] as num).toDouble();
          polygonRing.add(LatLng(lat, lng));
        }
      }
    }
    return polygonRing;
  }
}
