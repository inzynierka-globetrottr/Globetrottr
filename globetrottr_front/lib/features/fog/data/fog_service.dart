import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';

class FogService {
  final String? _backendUrl = dotenv.env['BACKEND_URL'];

  Future<List<List<LatLng>>> getFriendFog(String friendUsername) async {
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
    final data = jsonDecode(responseBody);
    final List<dynamic> coordinates = data['coordinates'] ?? data;

    List<List<LatLng>> holes = [];

    for (var polygon in coordinates) {
      for (var ring in polygon) {
        List<LatLng> polygonRing = [];
        for (var point in ring) {
          final double lng = (point[0] as num).toDouble();
          final double lat = (point[1] as num).toDouble();
          polygonRing.add(LatLng(lat, lng));
        }
        holes.add(polygonRing);
      }
    }

    return holes;
  }
}
