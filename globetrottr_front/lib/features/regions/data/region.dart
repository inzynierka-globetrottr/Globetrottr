import 'dart:typed_data';

import 'package:globetrottr_front/features/regions/data/region_type.dart';

class Region {
  final int id;
  final int? parentId;
  final String name;
  final RegionType type;
  final String? code;
  final double totalAreaKm2;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final Uint8List? geometry;

  const Region({
    required this.id,
    required this.parentId,
    required this.name,
    required this.type,
    required this.code,
    required this.totalAreaKm2,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    this.geometry,
  });

  bool containsPoint(double lat, double lon) {
    if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
      return false;
    }
    // If exact polygon geometry is present, point-in-polygon can be evaluated here.
    return true;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'type': type.name,
      'code': code,
      'total_area_km2': totalAreaKm2,
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lon': minLon,
      'max_lon': maxLon,
      'geometry': geometry,
    };
  }

  factory Region.fromMap(Map<String, Object?> map) {
    return Region(
      id: map['id']! as int,
      parentId: map['parent_id'] as int?,
      name: map['name']! as String,
      type: RegionType.fromString(map['type']! as String),
      code: map['code'] as String?,
      totalAreaKm2: (map['total_area_km2']! as num).toDouble(),
      minLat: (map['min_lat']! as num).toDouble(),
      maxLat: (map['max_lat']! as num).toDouble(),
      minLon: (map['min_lon']! as num).toDouble(),
      maxLon: (map['max_lon']! as num).toDouble(),
      geometry: map['geometry'] == null
          ? null
          : Uint8List.fromList(map['geometry']! as List<int>),
    );
  }
}
