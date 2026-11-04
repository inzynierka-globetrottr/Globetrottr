import 'package:flutter/foundation.dart';
import 'package:globetrottr_front/features/regions/data/region_geometry.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';

/// A region's name with its translations; widgets pick one with the app
/// language.
@immutable
class RegionName {
  const RegionName(this.local, {this.en, this.pl});

  final String local;
  final String? en;
  final String? pl;

  String of(String languageCode) => switch (languageCode) {
    'pl' => pl ?? local,
    'en' => en ?? local,
    _ => local,
  };

  @override
  bool operator ==(Object other) =>
      other is RegionName &&
      other.local == local &&
      other.en == en &&
      other.pl == pl;

  @override
  int get hashCode => Object.hash(local, en, pl);
}

class Region {
  final int id;
  final int? parentId;
  final String name;
  final String? nameEn;
  final String? namePl;
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
    this.nameEn,
    this.namePl,
    required this.type,
    required this.code,
    required this.totalAreaKm2,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    this.geometry,
  });

  RegionName get displayName => RegionName(name, en: nameEn, pl: namePl);

  /// The name in [languageCode] when the data has a translation, else the
  /// local name.
  String localizedName(String languageCode) => displayName.of(languageCode);

  /// A region without a boundary covers its whole bounding box.
  bool containsPoint(double lat, double lon) {
    if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
      return false;
    }
    final boundary = geometry;
    if (boundary == null || boundary.isEmpty) return true;
    return regionGeometryContains(boundary, lat, lon);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'name_en': nameEn,
      'name_pl': namePl,
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
      nameEn: map['name_en'] as String?,
      namePl: map['name_pl'] as String?,
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
