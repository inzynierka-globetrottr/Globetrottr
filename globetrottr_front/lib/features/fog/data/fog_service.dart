import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/network/api_client.dart';
import 'package:latlong2/latlong.dart';

class FogService {
  final ApiClient _client;

  FogService(this._client);

  Future<List<List<LatLng>>> getMyFog() async {
    final response = await _client.get('/api/fog/me');
    return _parseMultiPolygon(response.body);
  }

  Future<List<List<LatLng>>> getFriendFog(String friendUsername) async {
    final response = await _client.get('/api/fog/$friendUsername');
    return _parseMultiPolygon(response.body);
  }

  List<List<LatLng>> _parseMultiPolygon(String responseBody) {
    final Map<String, dynamic> data = jsonDecode(responseBody);

    final dynamic coordinates = data['coordinates'];

    if (coordinates == null) return [];

    final List<List<LatLng>> holes = [];
    final String type = data['type'] ?? 'Polygon';

    if (type == 'Polygon') {
      for (final ring in coordinates) {
        holes.add(_parseRing(ring));
      }
    } else if (type == 'MultiPolygon') {
      for (final polygon in coordinates) {
        for (final ring in polygon) {
          holes.add(_parseRing(ring));
        }
      }
    }

    return holes;
  }

  List<LatLng> _parseRing(dynamic ring) {
    final List<LatLng> polygonRing = [];
    if (ring is List) {
      for (final point in ring) {
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

final fogServiceProvider = Provider<FogService>(
  (ref) => FogService(ref.read(apiClientProvider)),
);
