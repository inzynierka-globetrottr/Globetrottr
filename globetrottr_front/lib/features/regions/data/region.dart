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
    if (geometry == null || geometry!.isEmpty) {
      return true;
    }
    return _pointInGeometry(geometry!, lat, lon);
  }

  static bool _pointInGeometry(Uint8List geometry, double lat, double lon) {
    if (geometry.length < 2) return false;
    final byteData = ByteData.sublistView(geometry);
    final numRings = byteData.getUint16(0, Endian.little);
    var offset = 2;
    var inside = false;

    for (var r = 0; r < numRings; r++) {
      if (offset + 2 > geometry.length) break;
      final numPoints = byteData.getUint16(offset, Endian.little);
      offset += 2;
      if (offset + numPoints * 8 > geometry.length) break;

      if (numPoints < 3) {
        offset += numPoints * 8;
        continue;
      }

      final lastPtOffset = offset + (numPoints - 1) * 8;
      var x1 = byteData.getFloat32(lastPtOffset, Endian.little);
      var y1 = byteData.getFloat32(lastPtOffset + 4, Endian.little);

      for (var i = 0; i < numPoints; i++) {
        final x2 = byteData.getFloat32(offset, Endian.little);
        final y2 = byteData.getFloat32(offset + 4, Endian.little);
        offset += 8;

        final intersects =
            ((y1 > lat) != (y2 > lat)) &&
            (lon < (x2 - x1) * (lat - y1) / (y2 - y1) + x1);
        if (intersects) {
          inside = !inside;
        }
        x1 = x2;
        y1 = y2;
      }
    }

    return inside;
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
